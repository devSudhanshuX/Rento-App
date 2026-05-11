from django.db import models
import uuid


class Room(models.Model):
    """Room model for Rento application."""
    
    ROOM_TYPE_CHOICES = [
        ('1BHK', '1BHK'),
        ('2BHK', '2BHK'),
        ('3BHK', '3BHK'),
        ('Studio', 'Studio'),
        ('Shared', 'Shared'),
    ]
    
    id = models.CharField(max_length=255, primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    security_deposit = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    location = models.CharField(max_length=255)
    city = models.CharField(max_length=120, blank=True)
    address = models.CharField(max_length=500, blank=True)
    contact_number = models.CharField(max_length=30, blank=True)
    owner_name = models.CharField(max_length=255, blank=True)
    images = models.JSONField(default=list, blank=True)
    room_type = models.CharField(max_length=20, choices=ROOM_TYPE_CHOICES, blank=True, null=True)
    furnishing = models.CharField(max_length=50, blank=True)
    preferred_tenant = models.CharField(max_length=50, blank=True)
    available_from = models.DateField(blank=True, null=True)
    rules = models.JSONField(default=list, blank=True)
    is_available = models.BooleanField(default=True)
    owner_id = models.CharField(max_length=255)
    amenities = models.JSONField(default=list, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'app_rooms'
        verbose_name = 'Room'
        verbose_name_plural = 'Rooms'
    
    def __str__(self):
        return self.title
    
    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'price': str(self.price),
            'securityDeposit': str(self.security_deposit),
            'location': self.location,
            'city': self.city,
            'address': self.address,
            'contactNumber': self.contact_number,
            'ownerName': self.owner_name,
            'images': self.images,
            'roomType': self.room_type,
            'furnishing': self.furnishing,
            'preferredTenant': self.preferred_tenant,
            'availableFrom': self.available_from.isoformat() if self.available_from else None,
            'rules': self.rules,
            'isAvailable': self.is_available,
            'ownerId': self.owner_id,
            'amenities': self.amenities,
            'createdAt': self.created_at.isoformat() if self.created_at else None,
        }


class SavedRoom(models.Model):
    """Room saved by a user."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user_id = models.CharField(max_length=255)
    room = models.ForeignKey(Room, on_delete=models.CASCADE, related_name='saved_by')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'app_saved_rooms'
        unique_together = ('user_id', 'room')
        verbose_name = 'Saved Room'
        verbose_name_plural = 'Saved Rooms'

    def __str__(self):
        return f"{self.user_id} saved {self.room_id}"


class Notification(models.Model):
    """Notification shown in the app notification tray."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user_id = models.CharField(max_length=255)
    title = models.CharField(max_length=255)
    body = models.TextField(blank=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'app_notifications'
        ordering = ['-created_at']
        verbose_name = 'Notification'
        verbose_name_plural = 'Notifications'

    def __str__(self):
        return f"{self.title} ({self.user_id})"


class RoomInquiry(models.Model):
    """Contact request sent by a room seeker to a room owner."""

    STATUS_CHOICES = [
        ('new', 'New'),
        ('contacted', 'Contacted'),
        ('closed', 'Closed'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    room = models.ForeignKey(Room, on_delete=models.CASCADE, related_name='inquiries')
    tenant_id = models.CharField(max_length=255)
    tenant_name = models.CharField(max_length=255)
    tenant_email = models.EmailField(blank=True)
    tenant_phone = models.CharField(max_length=30, blank=True)
    message = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='new')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'app_room_inquiries'
        ordering = ['-created_at']
        verbose_name = 'Room Inquiry'
        verbose_name_plural = 'Room Inquiries'

    def __str__(self):
        return f"{self.tenant_name} → {self.room.title}"


class Review(models.Model):
    """Rating and review exchanged between tenants and owners."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    reviewer_id = models.CharField(max_length=255)
    reviewer_name = models.CharField(max_length=255, blank=True)
    reviewed_user_id = models.CharField(max_length=255)
    room = models.ForeignKey(Room, on_delete=models.SET_NULL, related_name='reviews', blank=True, null=True)
    rating = models.PositiveSmallIntegerField()
    comment = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'app_reviews'
        ordering = ['-created_at']
        verbose_name = 'Review'
        verbose_name_plural = 'Reviews'

    def __str__(self):
        return f"{self.rating} star review for {self.reviewed_user_id}"
