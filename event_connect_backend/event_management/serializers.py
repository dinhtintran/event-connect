from rest_framework import serializers
from .models import Event, EventRegistration, Feedback, EventApproval, EventImage
from accounts.serializers import UserSerializer
from clubs.serializers import ClubSerializer


class EventImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = EventImage
        fields = ('id', 'image', 'caption', 'order', 'uploaded_at')
        read_only_fields = ('id', 'uploaded_at')


class EventListSerializer(serializers.ModelSerializer):
    club = ClubSerializer(read_only=True)
    is_full = serializers.ReadOnlyField()
    is_registration_open = serializers.ReadOnlyField()
    
    class Meta:
        model = Event
        fields = (
            'id', 'title', 'slug', 'description', 'category', 'club',
            'location', 'start_at', 'end_at', 'registration_start', 'registration_end',
            'capacity', 'registration_count', 'is_full', 'is_registration_open',
            'poster', 'status', 'is_featured', 'view_count', 'average_rating',
            'rating_count', 'created_at'
        )


class EventDetailSerializer(serializers.ModelSerializer):
    club = ClubSerializer(read_only=True)
    created_by = UserSerializer(read_only=True)
    images = EventImageSerializer(many=True, read_only=True)
    is_full = serializers.ReadOnlyField()
    is_registration_open = serializers.ReadOnlyField()
    user_registration = serializers.SerializerMethodField()
    
    class Meta:
        model = Event
        fields = (
            'id', 'title', 'slug', 'description', 'category', 'club', 'created_by',
            'location', 'location_detail', 'start_at', 'end_at',
            'registration_start', 'registration_end', 'capacity', 'registration_count',
            'is_full', 'is_registration_open', 'poster', 'banner', 'images',
            'status', 'is_featured', 'requires_approval', 'view_count',
            'average_rating', 'rating_count', 'user_registration',
            'created_at', 'updated_at'
        )
    
    def get_user_registration(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            registration = EventRegistration.objects.filter(
                event=obj, user=request.user
            ).first()
            if registration:
                return {
                    'is_registered': True,
                    'registration_id': registration.id,
                    'registered_at': registration.registered_at,
                    'status': registration.status
                }
        return {'is_registered': False}


class EventCreateUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Event
        fields = (
            'title', 'description', 'category', 'location', 'location_detail',
            'start_at', 'end_at', 'registration_start', 'registration_end',
            'capacity', 'poster', 'banner', 'requires_approval'
        )
    
    def validate(self, data):
        if data.get('start_at') and data.get('end_at'):
            if data['end_at'] <= data['start_at']:
                raise serializers.ValidationError({
                    'end_at': 'End time must be after start time'
                })
        
        if data.get('registration_start') and data.get('registration_end'):
            if data['registration_end'] <= data['registration_start']:
                raise serializers.ValidationError({
                    'registration_end': 'Registration end must be after registration start'
                })
        
        return data


class EventFeaturedSerializer(serializers.ModelSerializer):
    class Meta:
        model = Event
        fields = (
            'id', 'title', 'poster', 'start_at', 'category',
            'registration_count', 'capacity', 'average_rating'
        )


class EventRegistrationSerializer(serializers.ModelSerializer):
    event = EventListSerializer(read_only=True)
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = EventRegistration
        fields = (
            'id', 'event', 'user', 'status', 'note', 'qr_code',
            'checked_in', 'checked_in_at', 'registered_at', 'updated_at'
        )
        read_only_fields = ('id', 'qr_code', 'checked_in', 'checked_in_at', 'registered_at', 'updated_at')


class EventRegistrationCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = EventRegistration
        fields = ('note',)


class ParticipantSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = EventRegistration
        fields = (
            'id', 'user', 'status', 'checked_in', 'registered_at'
        )


class FeedbackSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = Feedback
        fields = (
            'id', 'user', 'rating', 'comment', 'created_at'
        )


class FeedbackCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Feedback
        fields = ('rating', 'comment', 'is_anonymous')
    
    def validate_rating(self, value):
        if value < 1 or value > 5:
            raise serializers.ValidationError('Rating must be between 1 and 5')
        return value


class EventApprovalSerializer(serializers.ModelSerializer):
    event = EventListSerializer(read_only=True)
    reviewer = UserSerializer(read_only=True)
    
    class Meta:
        model = EventApproval
        fields = (
            'id', 'event', 'reviewer', 'status', 'comment',
            'submitted_at', 'reviewed_at'
        )


class EventApprovalActionSerializer(serializers.Serializer):
    comment = serializers.CharField(required=False, allow_blank=True)
