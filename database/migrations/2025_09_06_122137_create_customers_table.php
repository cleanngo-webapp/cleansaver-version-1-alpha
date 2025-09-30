<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('customers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained('users')->cascadeOnDelete();
            $table->foreignId('default_address_id')->nullable()->constrained('addresses')->nullOnDelete();
            $table->text('notes')->nullable();
        });
    }

    public function down(): void {
        Schema::dropIfExists('customers');
    }
};

