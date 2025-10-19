<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('tasks', function (Blueprint $table) {
        $table->id();
        $table->foreignId('user_id')->constrained()->onDelete('cascade'); // Khóa ngoại tới bảng users
        $table->string('title');
        $table->text('note')->nullable(); // Cho phép ghi chú trống
        $table->date('due_date');
        $table->boolean('is_completed')->default(false);
        $table->boolean('is_fixed')->default(false);
        $table->string('type')->nullable(); // Loại công việc cố định (vd: breakfast)
        $table->timestamps();
    });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tasks');
    }
};
