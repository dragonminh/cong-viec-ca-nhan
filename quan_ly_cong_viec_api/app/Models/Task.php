<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Task extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'user_id',
        'title',
        'note',
        'due_date',
        'is_completed',
        'is_fixed',
        'type',
    ];

    /**
     * Lấy user sở hữu công việc này.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}