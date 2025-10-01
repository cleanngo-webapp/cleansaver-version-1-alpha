<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Drop unused tables that are no longer needed in the application.
     * These tables were created for features that were never implemented or are no longer used.
     * 
     * Tables being dropped:
     * - payroll_periods: Payroll management feature not implemented
     * - payroll_items: Payroll management feature not implemented  
     * - job_photos: Photo upload feature not implemented
     * - job_time_logs: Time tracking feature not implemented
     * - inventory_transactions: Inventory tracking feature not implemented
     * - employee_time_off: Employee time-off management not implemented
     * - employee_availability: Employee scheduling not implemented
     * - booking_addons: Service addons feature not implemented
     * - booking_ratings: Customer rating system not implemented
     */
    public function up(): void {
        // Drop tables in reverse dependency order to avoid foreign key constraint issues
        
        // Drop dependent tables first
        Schema::dropIfExists('payroll_items'); // Depends on payroll_periods
        Schema::dropIfExists('booking_addons'); // Depends on bookings and service_addons
        Schema::dropIfExists('booking_ratings'); // Depends on bookings and customers
        Schema::dropIfExists('job_photos'); // Depends on bookings and employees
        Schema::dropIfExists('job_time_logs'); // Depends on bookings and employees
        Schema::dropIfExists('inventory_transactions'); // Depends on inventory_items, bookings, employees
        
        // Drop independent tables
        Schema::dropIfExists('payroll_periods');
        Schema::dropIfExists('employee_time_off'); // Depends on employees
        Schema::dropIfExists('employee_availability'); // Depends on employees
    }

    /**
     * Recreate all dropped tables on rollback.
     * This allows you to undo the migration if needed.
     */
    public function down(): void {
        // Recreate tables in dependency order
        
        // Independent tables first
        Schema::create('payroll_periods', function (Blueprint $table) {
            $table->id();
            $table->date('start_date');
            $table->date('end_date');
            $table->date('payout_date');
            $table->timestamps();
        });

        Schema::create('employee_time_off', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained('employees')->cascadeOnDelete();
            $table->date('start_date');
            $table->date('end_date');
            $table->text('reason')->nullable();
        });

        Schema::create('employee_availability', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained('employees')->cascadeOnDelete();
            $table->tinyInteger('day_of_week'); // 0 = Sunday, 6 = Saturday
            $table->string('start_time'); // stored as HH:MM
            $table->string('end_time');
            $table->unique(['employee_id', 'day_of_week', 'start_time', 'end_time']);
        });

        // Dependent tables
        Schema::create('payroll_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('payroll_period_id')->constrained('payroll_periods')->cascadeOnDelete();
            $table->foreignId('employee_id')->constrained('employees')->cascadeOnDelete();
            $table->integer('hours_worked')->default(0);
            $table->integer('base_pay_cents');
            $table->integer('overtime_pay_cents')->default(0);
            $table->integer('bonus_cents')->default(0);
            $table->integer('deductions_cents')->default(0);
            $table->integer('net_pay_cents');
            $table->timestamps();

            $table->unique(['payroll_period_id', 'employee_id']);
        });

        Schema::create('booking_addons', function (Blueprint $table) {
            $table->foreignId('booking_id')->constrained('bookings')->cascadeOnDelete();
            $table->foreignId('addon_id')->constrained('service_addons')->restrictOnDelete();
            $table->integer('quantity')->unsigned()->default(1);
            $table->integer('unit_price_cents')->unsigned();
            $table->primary(['booking_id', 'addon_id']);
        });

        Schema::create('booking_ratings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->unique()->constrained('bookings')->cascadeOnDelete();
            $table->foreignId('customer_id')->constrained('customers')->restrictOnDelete();
            $table->tinyInteger('rating'); // 1–5
            $table->text('comment')->nullable();
            $table->dateTime('created_at')->useCurrent();
        });

        Schema::create('job_photos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->constrained('bookings')->cascadeOnDelete();
            $table->foreignId('employee_id')->nullable()->constrained('employees')->nullOnDelete();
            $table->string('file_path');
            $table->text('caption')->nullable();
            $table->dateTime('uploaded_at')->useCurrent();
        });

        Schema::create('job_time_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->constrained('bookings')->cascadeOnDelete();
            $table->foreignId('employee_id')->constrained('employees')->cascadeOnDelete();
            $table->dateTime('clock_in');
            $table->dateTime('clock_out')->nullable();
            // minutes_worked is a computed column in SQLite; emulate with accessor in Laravel
            $table->unique(['booking_id', 'employee_id', 'clock_in']);

            $table->index(['employee_id', 'clock_in']);
            $table->index('booking_id');
        });

        Schema::create('inventory_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('item_id')->constrained('inventory_items')->cascadeOnDelete();
            $table->foreignId('booking_id')->nullable()->constrained('bookings')->nullOnDelete();
            $table->foreignId('employee_id')->nullable()->constrained('employees')->nullOnDelete();
            $table->enum('type', ['purchase','adjustment_in','adjustment_out','usage']);
            $table->decimal('quantity', 10, 2);
            $table->integer('unit_cost_cents')->nullable();
            $table->text('reason')->nullable();
            $table->dateTime('created_at')->useCurrent();

            $table->index(['item_id', 'created_at']);
            $table->index('booking_id');
        });
    }
};