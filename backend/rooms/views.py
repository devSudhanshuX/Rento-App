import mimetypes
import re
import uuid
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen

from django.conf import settings
from rest_framework import status
from rest_framework.decorators import api_view, parser_classes
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from .models import Notification, Review, Room, RoomInquiry, SavedRoom
from .serializers import (
    NotificationSerializer,
    ReviewSerializer,
    RoomInquirySerializer,
    RoomSerializer,
    SavedRoomSerializer,
)


def _safe_storage_name(file_name):
    safe_name = re.sub(r'[^A-Za-z0-9_.-]', '_', file_name or 'room-photo.jpg')
    return safe_name[:120] or 'room-photo.jpg'


def _upload_to_supabase_storage(path, uploaded_file):
    service_key = settings.SUPABASE_SERVICE_KEY
    if not service_key:
        raise RuntimeError('SUPABASE_SERVICE_KEY is not configured in backend/.env')

    content_type = uploaded_file.content_type or mimetypes.guess_type(uploaded_file.name)[0]
    if not content_type or not content_type.startswith('image/'):
        content_type = 'image/jpeg'

    bucket = settings.SUPABASE_STORAGE_BUCKET
    storage_path = quote(path, safe='/')
    upload_url = f'{settings.SUPABASE_URL}/storage/v1/object/{bucket}/{storage_path}'
    request = Request(
        upload_url,
        data=uploaded_file.read(),
        method='POST',
        headers={
            'apikey': service_key,
            'Authorization': f'Bearer {service_key}',
            'Content-Type': content_type,
            'Cache-Control': '3600',
            'x-upsert': 'false',
        },
    )

    with urlopen(request, timeout=30):
        pass

    return f'{settings.SUPABASE_URL}/storage/v1/object/public/{bucket}/{storage_path}'


@api_view(['GET'])
def get_all_rooms(request):
    """Get all rooms."""
    rooms = Room.objects.all().order_by('-created_at')

    query = request.query_params.get('q')
    city = request.query_params.get('city')
    room_type = request.query_params.get('roomType') or request.query_params.get('room_type')
    furnishing = request.query_params.get('furnishing')
    preferred_tenant = request.query_params.get('preferredTenant') or request.query_params.get('preferred_tenant')
    min_price = request.query_params.get('minPrice') or request.query_params.get('min_price')
    max_price = request.query_params.get('maxPrice') or request.query_params.get('max_price')
    amenity = request.query_params.get('amenity')

    if query:
        rooms = rooms.filter(title__icontains=query) | rooms.filter(location__icontains=query) | rooms.filter(city__icontains=query)
    if city and city != 'All':
        rooms = rooms.filter(city__icontains=city)
    if room_type and room_type != 'All':
        rooms = rooms.filter(room_type=room_type)
    if furnishing and furnishing != 'All':
        rooms = rooms.filter(furnishing=furnishing)
    if preferred_tenant and preferred_tenant != 'All':
        rooms = rooms.filter(preferred_tenant=preferred_tenant)
    if min_price:
        rooms = rooms.filter(price__gte=min_price)
    if max_price:
        rooms = rooms.filter(price__lte=max_price)
    if amenity and amenity != 'All':
        rooms = rooms.filter(amenities__contains=[amenity])

    serializer = RoomSerializer(rooms, many=True)
    return Response(serializer.data)


@api_view(['POST'])
@parser_classes([MultiPartParser, FormParser])
def upload_room_images(request):
    """Upload room images through Django so Storage policies are not needed."""
    room_id = request.data.get('roomId') or request.data.get('room_id')
    images = request.FILES.getlist('images')

    if not room_id:
        return Response(
            {'error': 'Missing required field: roomId'},
            status=status.HTTP_400_BAD_REQUEST,
        )
    if not images:
        return Response(
            {'error': 'Please select at least one room photo'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    uploaded_urls = []
    try:
        for index, image in enumerate(images):
            safe_name = _safe_storage_name(image.name)
            object_path = f'{room_id}/{uuid.uuid4().hex}_{index}_{safe_name}'
            uploaded_urls.append(_upload_to_supabase_storage(object_path, image))
    except HTTPError as exc:
        details = exc.read().decode('utf-8', errors='replace')
        return Response(
            {'error': 'Supabase Storage upload failed', 'details': details},
            status=exc.code,
        )
    except (URLError, TimeoutError, RuntimeError) as exc:
        return Response(
            {'error': 'Supabase Storage upload failed', 'details': str(exc)},
            status=status.HTTP_502_BAD_GATEWAY,
        )

    return Response({'images': uploaded_urls}, status=status.HTTP_201_CREATED)


@api_view(['POST'])
def create_room(request):
    """Create a new room."""
    # Convert camelCase to snake_case for processing
    data = request.data.copy()
    
    # Map camelCase fields to snake_case
    if 'ownerId' in data and 'owner_id' not in data:
        data['owner_id'] = data.pop('ownerId')
    if 'roomType' in data and 'room_type' not in data:
        data['room_type'] = data.pop('roomType')
    if 'securityDeposit' in data and 'security_deposit' not in data:
        data['security_deposit'] = data.pop('securityDeposit')
    if 'contactNumber' in data and 'contact_number' not in data:
        data['contact_number'] = data.pop('contactNumber')
    if 'ownerName' in data and 'owner_name' not in data:
        data['owner_name'] = data.pop('ownerName')
    if 'preferredTenant' in data and 'preferred_tenant' not in data:
        data['preferred_tenant'] = data.pop('preferredTenant')
    if 'availableFrom' in data and 'available_from' not in data:
        data['available_from'] = data.pop('availableFrom')
    if 'isAvailable' in data and 'is_available' not in data:
        data['is_available'] = data.pop('isAvailable')
    
    required_fields = ['id', 'title', 'price', 'location', 'owner_id']
    
    # Check for required fields
    missing_fields = [field for field in required_fields if not data.get(field)]
    if missing_fields:
        return Response(
            {'error': f'Missing required fields: {", ".join(missing_fields)}'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Check if room already exists
    room_id = data.get('id')
    if Room.objects.filter(id=room_id).exists():
        return Response(
            {'error': 'Room with this ID already exists'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    serializer = RoomSerializer(data=data)
    if serializer.is_valid():
        room = serializer.save()
        Notification.objects.create(
            user_id=room.owner_id,
            title='Room listed',
            body=f'{room.title} has been added to your listings.'
        )
        return Response({
            'message': 'Room created successfully',
            'room': serializer.data
        }, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PUT', 'DELETE'])
def room_detail(request, room_id):
    """Get, update, or delete a specific room by ID."""
    try:
        room = Room.objects.get(id=room_id)
    except Room.DoesNotExist:
        return Response(
            {'error': 'Room not found'},
            status=status.HTTP_404_NOT_FOUND
        )

    if request.method == 'GET':
        serializer = RoomSerializer(room)
        return Response(serializer.data)

    if request.method == 'DELETE':
        room.delete()
        return Response({'message': 'Room deleted successfully'})

    data = request.data.copy()
    if 'ownerId' in data and 'owner_id' not in data:
        data['owner_id'] = data.pop('ownerId')
    if 'roomType' in data and 'room_type' not in data:
        data['room_type'] = data.pop('roomType')
    if 'securityDeposit' in data and 'security_deposit' not in data:
        data['security_deposit'] = data.pop('securityDeposit')
    if 'contactNumber' in data and 'contact_number' not in data:
        data['contact_number'] = data.pop('contactNumber')
    if 'ownerName' in data and 'owner_name' not in data:
        data['owner_name'] = data.pop('ownerName')
    if 'preferredTenant' in data and 'preferred_tenant' not in data:
        data['preferred_tenant'] = data.pop('preferredTenant')
    if 'availableFrom' in data and 'available_from' not in data:
        data['available_from'] = data.pop('availableFrom')
    if 'isAvailable' in data and 'is_available' not in data:
        data['is_available'] = data.pop('isAvailable')

    serializer = RoomSerializer(room, data=data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response({
            'message': 'Room updated successfully',
            'room': serializer.data
        })

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
def get_rooms_by_owner(request, owner_id):
    """Get all rooms by owner ID."""
    rooms = Room.objects.filter(owner_id=owner_id)
    serializer = RoomSerializer(rooms, many=True)
    return Response(serializer.data)


@api_view(['GET'])
def get_saved_rooms(request, user_id):
    """Get all rooms saved by a user."""
    saved_rooms = SavedRoom.objects.filter(user_id=user_id).select_related('room')
    serializer = SavedRoomSerializer(saved_rooms, many=True)
    return Response(serializer.data)


@api_view(['POST'])
def toggle_saved_room(request):
    """Save or unsave a room for a user."""
    user_id = request.data.get('userId') or request.data.get('user_id')
    room_id = request.data.get('roomId') or request.data.get('room_id')

    if not user_id or not room_id:
        return Response(
            {'error': 'Missing required fields: userId, roomId'},
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        room = Room.objects.get(id=room_id)
    except Room.DoesNotExist:
        return Response({'error': 'Room not found'}, status=status.HTTP_404_NOT_FOUND)

    saved_room = SavedRoom.objects.filter(user_id=user_id, room=room).first()
    if saved_room:
        saved_room.delete()
        return Response({'saved': False, 'message': 'Room removed from saved'})

    saved_room = SavedRoom.objects.create(user_id=user_id, room=room)
    serializer = SavedRoomSerializer(saved_room)
    return Response(
        {'saved': True, 'message': 'Room saved', 'savedRoom': serializer.data},
        status=status.HTTP_201_CREATED
    )


@api_view(['GET'])
def get_notifications(request, user_id):
    """Get all notifications for a user."""
    notifications = Notification.objects.filter(user_id=user_id)
    serializer = NotificationSerializer(notifications, many=True)
    return Response(serializer.data)


@api_view(['POST'])
def create_notification(request):
    """Create a notification for a user."""
    data = request.data.copy()
    if 'userId' in data and 'user_id' not in data:
        data['user_id'] = data.pop('userId')

    required_fields = ['user_id', 'title']
    missing_fields = [field for field in required_fields if not data.get(field)]
    if missing_fields:
        return Response(
            {'error': f'Missing required fields: {", ".join(missing_fields)}'},
            status=status.HTTP_400_BAD_REQUEST
        )

    serializer = NotificationSerializer(data=data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['PUT'])
def mark_notification_read(request, notification_id):
    """Mark a notification as read."""
    try:
        notification = Notification.objects.get(id=notification_id)
    except Notification.DoesNotExist:
        return Response(
            {'error': 'Notification not found'},
            status=status.HTTP_404_NOT_FOUND
        )

    notification.is_read = True
    notification.save(update_fields=['is_read'])
    serializer = NotificationSerializer(notification)
    return Response(serializer.data)


@api_view(['POST'])
def create_inquiry(request):
    """Create a contact request for a room owner."""
    data = request.data.copy()

    field_map = {
        'roomId': 'room_id',
        'tenantId': 'tenant_id',
        'tenantName': 'tenant_name',
        'tenantEmail': 'tenant_email',
        'tenantPhone': 'tenant_phone',
    }
    for source, target in field_map.items():
        if source in data and target not in data:
            data[target] = data.pop(source)

    required_fields = ['room_id', 'tenant_id', 'tenant_name', 'message']
    missing_fields = [field for field in required_fields if not data.get(field)]
    if missing_fields:
        return Response(
            {'error': f'Missing required fields: {", ".join(missing_fields)}'},
            status=status.HTTP_400_BAD_REQUEST
        )

    serializer = RoomInquirySerializer(data=data)
    if serializer.is_valid():
        inquiry = serializer.save()
        Notification.objects.create(
            user_id=inquiry.room.owner_id,
            title='New room inquiry',
            body=f'{inquiry.tenant_name} is interested in {inquiry.room.title}.'
        )
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
def get_owner_inquiries(request, owner_id):
    """Get contact requests for all rooms owned by a user."""
    inquiries = RoomInquiry.objects.filter(room__owner_id=owner_id).select_related('room')
    serializer = RoomInquirySerializer(inquiries, many=True)
    return Response(serializer.data)


@api_view(['GET'])
def get_tenant_inquiries(request, tenant_id):
    """Get contact requests created by a room seeker."""
    inquiries = RoomInquiry.objects.filter(tenant_id=tenant_id).select_related('room')
    serializer = RoomInquirySerializer(inquiries, many=True)
    return Response(serializer.data)


@api_view(['POST'])
def create_review(request):
    """Create a review for an owner or tenant."""
    data = request.data.copy()

    field_map = {
        'reviewerId': 'reviewer_id',
        'reviewerName': 'reviewer_name',
        'reviewedUserId': 'reviewed_user_id',
        'roomId': 'room_id',
    }
    for source, target in field_map.items():
        if source in data and target not in data:
            data[target] = data.pop(source)

    required_fields = ['reviewer_id', 'reviewed_user_id', 'rating']
    missing_fields = [field for field in required_fields if not data.get(field)]
    if missing_fields:
        return Response(
            {'error': f'Missing required fields: {", ".join(missing_fields)}'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    serializer = ReviewSerializer(data=data)
    if serializer.is_valid():
        review = serializer.save()
        Notification.objects.create(
            user_id=review.reviewed_user_id,
            title='New review received',
            body=f'{review.reviewer_name or "Someone"} rated you {review.rating}/5.',
        )
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
def get_reviews_for_user(request, user_id):
    """Get reviews received by a user."""
    reviews = Review.objects.filter(reviewed_user_id=user_id).select_related('room')
    serializer = ReviewSerializer(reviews, many=True)
    return Response(serializer.data)


@api_view(['GET'])
def get_reviews_by_user(request, user_id):
    """Get reviews written by a user."""
    reviews = Review.objects.filter(reviewer_id=user_id).select_related('room')
    serializer = ReviewSerializer(reviews, many=True)
    return Response(serializer.data)
