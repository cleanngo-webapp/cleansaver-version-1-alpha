<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class GalleryImage extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     * This allows us to safely assign these fields when creating/updating gallery images
     */
    protected $fillable = [
        'service_type',
        'image_path',
        'original_name',
        'alt_text',
        'sort_order',
        'is_active'
    ];

    /**
     * The attributes that should be cast to native types.
     * This ensures proper data type handling
     */
    protected $casts = [
        'is_active' => 'boolean',
        'sort_order' => 'integer'
    ];

    /**
     * Get the service type display name
     * Converts the service_type code to a human-readable format
     */
    public function getServiceDisplayNameAttribute()
    {
        $serviceNames = [
            'carpet' => 'Carpet Deep Cleaning',
            'disinfection' => 'Enhanced Disinfection',
            'glass' => 'Glass Cleaning',
            'carInterior' => 'Home Service Car Interior Detailing',
            'postConstruction' => 'Post Construction Cleaning',
            'sofa' => 'Sofa / Mattress Deep Cleaning'
        ];

        return $serviceNames[$this->service_type] ?? 'Unknown Service';
    }

    /**
     * Scope to get images for a specific service type
     * This makes it easy to filter images by service
     */
    public function scopeForService($query, $serviceType)
    {
        return $query->where('service_type', $serviceType);
    }

    /**
     * Scope to get only active images
     * This ensures we only show images that are meant to be displayed
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Scope to order images by sort_order
     * This allows us to control the display order of images
     */
    public function scopeOrdered($query)
    {
        return $query->orderBy('sort_order')->orderBy('created_at', 'desc');
    }
}
