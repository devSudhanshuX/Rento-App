import json
import mimetypes
import re
import uuid
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen

from django.conf import settings
from django.db.models import Avg
from rest_framework import status
from rest_framework.decorators import api_view, parser_classes
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rooms.models import Review, Room, RoomInquiry, SavedRoom
from .models import SupportTicket, User
from .serializers import SupportTicketSerializer, UserSerializer


def _map_profile_fields(data):
    """Accept both Flutter camelCase and Django snake_case payloads."""
    field_map = {
        'profilePhotoUrl': 'profile_photo_url',
        'alternateContact': 'alternate_contact',
        'dateOfBirth': 'date_of_birth',
        'isVerified': 'is_verified',
        'emailNotifications': 'email_notifications',
        'smsNotifications': 'sms_notifications',
        'appTheme': 'app_theme',
        'locationEnabled': 'location_enabled',
        'profileVisibility': 'profile_visibility',
        'twoFactorEnabled': 'two_factor_enabled',
    }
    mapped = data.copy()
    for source, target in field_map.items():
        if source in mapped and target not in mapped:
            mapped[target] = mapped.pop(source)
    if mapped.get('date_of_birth') == '':
        mapped['date_of_birth'] = None
    return mapped


def _safe_storage_name(file_name):
    safe_name = re.sub(r'[^A-Za-z0-9_.-]', '_', file_name or 'profile-photo.jpg')
    return safe_name[:120] or 'profile-photo.jpg'


def _ensure_storage_bucket(bucket):
    service_key = settings.SUPABASE_SERVICE_KEY
    if not service_key:
        raise RuntimeError('SUPABASE_SERVICE_KEY is not configured in backend/.env')

    headers = {
        'apikey': service_key,
        'Authorization': f'Bearer {service_key}',
    }
    bucket_url = f'{settings.SUPABASE_URL}/storage/v1/bucket/{bucket}'

    try:
        with urlopen(Request(bucket_url, headers=headers, method='GET'), timeout=20):
            return
    except HTTPError as exc:
        details = exc.read().decode('utf-8', errors='replace')
        if exc.code != 404 and 'Bucket not found' not in details:
            raise

    create_request = Request(
        f'{settings.SUPABASE_URL}/storage/v1/bucket',
        data=json.dumps({
            'id': bucket,
            'name': bucket,
            'public': True,
            'file_size_limit': 5242880,
            'allowed_mime_types': ['image/jpeg', 'image/png', 'image/webp'],
        }).encode('utf-8'),
        method='POST',
        headers={
            **headers,
            'Content-Type': 'application/json',
        },
    )
    with urlopen(create_request, timeout=20):
        pass


def _upload_profile_photo(user_id, uploaded_file):
    service_key = settings.SUPABASE_SERVICE_KEY
    if not service_key:
        raise RuntimeError('SUPABASE_SERVICE_KEY is not configured in backend/.env')

    content_type = uploaded_file.content_type or mimetypes.guess_type(uploaded_file.name)[0]
    if not content_type or not content_type.startswith('image/'):
        content_type = 'image/jpeg'

    safe_name = _safe_storage_name(uploaded_file.name)
    file_bytes = uploaded_file.read()

    # Profile photos must always live in their own Supabase Storage bucket.
    bucket = settings.SUPABASE_PROFILE_BUCKET
    if not bucket:
        raise RuntimeError('SUPABASE_PROFILE_BUCKET is not configured')

    def upload_once():
        object_path = f'{user_id}/{uuid.uuid4().hex}_{safe_name}'
        storage_path = quote(object_path, safe='/')
        upload_url = f'{settings.SUPABASE_URL}/storage/v1/object/{bucket}/{storage_path}'
        upload_request = Request(
            upload_url,
            data=file_bytes,
            method='POST',
            headers={
                'apikey': service_key,
                'Authorization': f'Bearer {service_key}',
                'Content-Type': content_type,
                'Cache-Control': '3600',
                'x-upsert': 'true',
            },
        )

        with urlopen(upload_request, timeout=30):
            pass

        return f'{settings.SUPABASE_URL}/storage/v1/object/public/{bucket}/{storage_path}'

    _ensure_storage_bucket(bucket)
    try:
        return upload_once()
    except HTTPError as exc:
        details = exc.read().decode('utf-8', errors='replace')
        if 'Bucket not found' in details:
            _ensure_storage_bucket(bucket)
            return upload_once()
        raise HTTPError(
            exc.url,
            exc.code,
            details or exc.reason,
            exc.headers,
            exc.fp,
        )


@api_view(['POST'])
def register_user(request):
    """Register a new user."""
    required_fields = ['id', 'name', 'email', 'phone', 'role']

    missing_fields = [field for field in required_fields if not request.data.get(field)]
    if missing_fields:
        return Response(
            {'error': f'Missing required fields: {", ".join(missing_fields)}'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    valid_roles = ['tenant', 'landowner', 'both']
    if request.data.get('role') not in valid_roles:
        return Response(
            {'error': f'Role must be one of: {", ".join(valid_roles)}'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    user_id = request.data.get('id')
    if User.objects.filter(id=user_id).exists():
        return Response(
            {'error': 'User with this ID already exists'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    serializer = UserSerializer(data=_map_profile_fields(request.data))
    if serializer.is_valid():
        serializer.save()
        return Response({
            'message': 'User registered successfully',
            'user': serializer.data,
        }, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
def get_user(request, user_id):
    """Get user profile by ID."""
    try:
        user = User.objects.get(id=user_id)
        serializer = UserSerializer(user)
        return Response(serializer.data)
    except User.DoesNotExist:
        return Response(
            {'error': 'User not found'},
            status=status.HTTP_404_NOT_FOUND,
        )


@api_view(['PUT'])
def update_user(request, user_id):
    """Update user profile."""
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response(
            {'error': 'User not found'},
            status=status.HTTP_404_NOT_FOUND,
        )

    serializer = UserSerializer(user, data=_map_profile_fields(request.data), partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response({
            'message': 'User updated successfully',
            'user': serializer.data,
        })

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
def profile_summary(request, user_id):
    """Get profile dashboard counts and trust indicators."""
    listings_count = Room.objects.filter(owner_id=user_id).count()
    saved_rooms_count = SavedRoom.objects.filter(user_id=user_id).count()
    tenant_inquiries = RoomInquiry.objects.filter(tenant_id=user_id)
    owner_inquiries_count = RoomInquiry.objects.filter(room__owner_id=user_id).count()
    bookings_count = tenant_inquiries.exclude(status='closed').count()
    booking_history_count = tenant_inquiries.filter(status='closed').count()
    reviews_received = Review.objects.filter(reviewed_user_id=user_id)
    reviews_given_count = Review.objects.filter(reviewer_id=user_id).count()
    rating_average = reviews_received.aggregate(value=Avg('rating'))['value'] or 0

    return Response({
        'myBookings': bookings_count,
        'myListings': listings_count,
        'bookingHistory': booking_history_count,
        'savedRooms': saved_rooms_count,
        'ownerInquiries': owner_inquiries_count,
        'ratingsReceivedAverage': round(rating_average, 1),
        'ratingsReceivedCount': reviews_received.count(),
        'reviewsGiven': reviews_given_count,
    })


@api_view(['POST'])
@parser_classes([MultiPartParser, FormParser])
def upload_profile_photo(request, user_id):
    """Upload and store a profile photo for a user."""
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response(
            {'error': 'User not found'},
            status=status.HTTP_404_NOT_FOUND,
        )

    image = request.FILES.get('image')
    if not image:
        return Response(
            {'error': 'Please select a profile photo'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        image_url = _upload_profile_photo(user_id, image)
    except HTTPError as exc:
        details = exc.read().decode('utf-8', errors='replace')
        return Response(
            {'error': 'Profile photo upload failed', 'details': details},
            status=exc.code,
        )
    except (URLError, TimeoutError, RuntimeError) as exc:
        return Response(
            {'error': 'Profile photo upload failed', 'details': str(exc)},
            status=status.HTTP_502_BAD_GATEWAY,
        )

    user.profile_photo_url = image_url
    user.save(update_fields=['profile_photo_url', 'updated_at'])
    return Response({'profilePhotoUrl': image_url, 'user': UserSerializer(user).data})


@api_view(['POST'])
def create_support_ticket(request):
    """Create a support ticket/report issue request."""
    data = request.data.copy()
    if 'userId' in data and 'user_id' not in data:
        data['user_id'] = data.pop('userId')
    if 'contactEmail' in data and 'contact_email' not in data:
        data['contact_email'] = data.pop('contactEmail')

    required_fields = ['user_id', 'subject', 'message']
    missing_fields = [field for field in required_fields if not data.get(field)]
    if missing_fields:
        return Response(
            {'error': f'Missing required fields: {", ".join(missing_fields)}'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    serializer = SupportTicketSerializer(data=data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
