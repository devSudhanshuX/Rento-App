from rest_framework import serializers
from .models import SupportTicket, User


class UserSerializer(serializers.ModelSerializer):
    """Serializer for User model."""

    id = serializers.CharField()
    
    class Meta:
        model = User
        fields = [
            'id',
            'name',
            'email',
            'phone',
            'role',
            'profile_photo_url',
            'alternate_contact',
            'gender',
            'date_of_birth',
            'is_verified',
            'email_notifications',
            'sms_notifications',
            'language',
            'app_theme',
            'location_enabled',
            'profile_visibility',
            'two_factor_enabled',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']
    
    def to_representation(self, instance):
        """Customize the output format to match the original API."""
        data = super().to_representation(instance)
        data['profilePhotoUrl'] = data.pop('profile_photo_url', None)
        data['alternateContact'] = data.pop('alternate_contact', None)
        data['dateOfBirth'] = data.pop('date_of_birth', None)
        data['isVerified'] = data.pop('is_verified', None)
        data['emailNotifications'] = data.pop('email_notifications', None)
        data['smsNotifications'] = data.pop('sms_notifications', None)
        data['appTheme'] = data.pop('app_theme', None)
        data['locationEnabled'] = data.pop('location_enabled', None)
        data['profileVisibility'] = data.pop('profile_visibility', None)
        data['twoFactorEnabled'] = data.pop('two_factor_enabled', None)
        data['createdAt'] = instance.created_at.isoformat() if instance.created_at else None
        data.pop('created_at', None)
        data.pop('updated_at', None)
        return data


class SupportTicketSerializer(serializers.ModelSerializer):
    """Serializer for profile support requests."""

    class Meta:
        model = SupportTicket
        fields = [
            'id',
            'user_id',
            'subject',
            'message',
            'contact_email',
            'status',
            'created_at',
        ]
        read_only_fields = ['id', 'status', 'created_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['userId'] = data.pop('user_id', None)
        data['contactEmail'] = data.pop('contact_email', None)
        data['createdAt'] = data.pop('created_at', None)
        return data
