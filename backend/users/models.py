from django.db import models
import uuid


class User(models.Model):
    """User model for Rento application."""
    
    ROLE_CHOICES = [
        ('tenant', 'Tenant'),
        ('landowner', 'Landowner'),
        ('both', 'Owner & Tenant'),
    ]

    GENDER_CHOICES = [
        ('', 'Prefer not to say'),
        ('female', 'Female'),
        ('male', 'Male'),
        ('non_binary', 'Non-binary'),
        ('other', 'Other'),
    ]

    THEME_CHOICES = [
        ('system', 'System'),
        ('light', 'Light'),
        ('dark', 'Dark'),
    ]

    PRIVACY_CHOICES = [
        ('public', 'Public'),
        ('private', 'Private'),
        ('contacts', 'Contacts only'),
    ]
    
    id = models.CharField(max_length=255, primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=20)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES)
    profile_photo_url = models.URLField(blank=True)
    alternate_contact = models.CharField(max_length=20, blank=True)
    gender = models.CharField(max_length=20, choices=GENDER_CHOICES, blank=True)
    date_of_birth = models.DateField(blank=True, null=True)
    is_verified = models.BooleanField(default=False)
    email_notifications = models.BooleanField(default=True)
    sms_notifications = models.BooleanField(default=False)
    language = models.CharField(max_length=40, default='English')
    app_theme = models.CharField(max_length=20, choices=THEME_CHOICES, default='system')
    location_enabled = models.BooleanField(default=True)
    profile_visibility = models.CharField(max_length=20, choices=PRIVACY_CHOICES, default='public')
    two_factor_enabled = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'app_users'
        verbose_name = 'User'
        verbose_name_plural = 'Users'
    
    def __str__(self):
        return f"{self.name} ({self.email})"
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'phone': self.phone,
            'role': self.role,
            'profilePhotoUrl': self.profile_photo_url,
            'alternateContact': self.alternate_contact,
            'gender': self.gender,
            'dateOfBirth': self.date_of_birth.isoformat() if self.date_of_birth else None,
            'isVerified': self.is_verified,
            'emailNotifications': self.email_notifications,
            'smsNotifications': self.sms_notifications,
            'language': self.language,
            'appTheme': self.app_theme,
            'locationEnabled': self.location_enabled,
            'profileVisibility': self.profile_visibility,
            'twoFactorEnabled': self.two_factor_enabled,
            'createdAt': self.created_at.isoformat() if self.created_at else None,
        }


class SupportTicket(models.Model):
    """Issue or help request submitted from the profile support section."""

    STATUS_CHOICES = [
        ('open', 'Open'),
        ('in_progress', 'In progress'),
        ('closed', 'Closed'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user_id = models.CharField(max_length=255)
    subject = models.CharField(max_length=255)
    message = models.TextField()
    contact_email = models.EmailField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'app_support_tickets'
        ordering = ['-created_at']
        verbose_name = 'Support Ticket'
        verbose_name_plural = 'Support Tickets'

    def __str__(self):
        return f"{self.subject} ({self.user_id})"
