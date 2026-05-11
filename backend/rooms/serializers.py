from rest_framework import serializers
from .models import Notification, Review, Room, RoomInquiry, SavedRoom


class RoomSerializer(serializers.ModelSerializer):
    """Serializer for Room model."""
    
    class Meta:
        model = Room
        fields = [
            'id',
            'title',
            'description',
            'price',
            'security_deposit',
            'location',
            'city',
            'address',
            'contact_number',
            'owner_name',
            'images',
            'room_type',
            'furnishing',
            'preferred_tenant',
            'available_from',
            'rules',
            'is_available',
            'owner_id',
            'amenities',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def to_representation(self, instance):
        """Customize the output format to match the original API."""
        data = super().to_representation(instance)
        data['createdAt'] = instance.created_at.isoformat() if instance.created_at else None
        data['securityDeposit'] = data.pop('security_deposit', None)
        data['contactNumber'] = data.pop('contact_number', None)
        data['ownerName'] = data.pop('owner_name', None)
        data['roomType'] = data.pop('room_type', None)
        data['preferredTenant'] = data.pop('preferred_tenant', None)
        data['availableFrom'] = data.pop('available_from', None)
        data['isAvailable'] = data.pop('is_available', None)
        data['ownerId'] = data.pop('owner_id', None)
        data.pop('created_at', None)
        data.pop('updated_at', None)
        return data


class SavedRoomSerializer(serializers.ModelSerializer):
    """Serializer for saved rooms."""

    room = RoomSerializer(read_only=True)

    class Meta:
        model = SavedRoom
        fields = ['id', 'user_id', 'room', 'created_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['userId'] = data.pop('user_id', None)
        data['createdAt'] = data.pop('created_at', None)
        return data


class NotificationSerializer(serializers.ModelSerializer):
    """Serializer for user notifications."""

    class Meta:
        model = Notification
        fields = ['id', 'user_id', 'title', 'body', 'is_read', 'created_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['userId'] = data.pop('user_id', None)
        data['isRead'] = data.pop('is_read', None)
        data['createdAt'] = data.pop('created_at', None)
        return data


class RoomInquirySerializer(serializers.ModelSerializer):
    """Serializer for contact requests between seekers and owners."""

    room = RoomSerializer(read_only=True)
    room_id = serializers.PrimaryKeyRelatedField(
        source='room',
        queryset=Room.objects.all(),
        write_only=True,
    )

    class Meta:
        model = RoomInquiry
        fields = [
            'id',
            'room',
            'room_id',
            'tenant_id',
            'tenant_name',
            'tenant_email',
            'tenant_phone',
            'message',
            'status',
            'created_at',
        ]
        extra_kwargs = {
            'room_id': {'write_only': True},
        }

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['roomId'] = instance.room_id
        data['tenantId'] = data.pop('tenant_id', None)
        data['tenantName'] = data.pop('tenant_name', None)
        data['tenantEmail'] = data.pop('tenant_email', None)
        data['tenantPhone'] = data.pop('tenant_phone', None)
        data['createdAt'] = data.pop('created_at', None)
        return data


class ReviewSerializer(serializers.ModelSerializer):
    """Serializer for user reviews and ratings."""

    room = RoomSerializer(read_only=True)
    room_id = serializers.PrimaryKeyRelatedField(
        source='room',
        queryset=Room.objects.all(),
        required=False,
        allow_null=True,
        write_only=True,
    )

    class Meta:
        model = Review
        fields = [
            'id',
            'reviewer_id',
            'reviewer_name',
            'reviewed_user_id',
            'room',
            'room_id',
            'rating',
            'comment',
            'created_at',
        ]
        extra_kwargs = {
            'room_id': {'write_only': True},
        }

    def validate_rating(self, value):
        if value < 1 or value > 5:
            raise serializers.ValidationError('Rating must be between 1 and 5.')
        return value

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['reviewerId'] = data.pop('reviewer_id', None)
        data['reviewerName'] = data.pop('reviewer_name', None)
        data['reviewedUserId'] = data.pop('reviewed_user_id', None)
        data['roomId'] = instance.room_id
        data['createdAt'] = data.pop('created_at', None)
        return data
