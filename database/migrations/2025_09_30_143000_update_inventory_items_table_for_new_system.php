<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // First, drop any dependent views that might reference the columns we want to drop
        DB::statement('DROP VIEW IF EXISTS inventory_stock_levels CASCADE');
        
        Schema::table('inventory_items', function (Blueprint $table) {
            // Remove old columns that are no longer needed
            if (Schema::hasColumn('inventory_items', 'sku')) {
                $table->dropColumn('sku');
            }
            if (Schema::hasColumn('inventory_items', 'min_stock')) {
                $table->dropColumn('min_stock');
            }
            if (Schema::hasColumn('inventory_items', 'unit')) {
                $table->dropColumn('unit');
            }
            
            // Add new columns that don't exist
            if (!Schema::hasColumn('inventory_items', 'item_code')) {
                $table->string('item_code')->unique()->after('id');
            }
            if (!Schema::hasColumn('inventory_items', 'category')) {
                $table->string('category')->after('name');
            }
            if (!Schema::hasColumn('inventory_items', 'quantity')) {
                $table->decimal('quantity', 10, 2)->default(0)->after('category');
            }
            if (!Schema::hasColumn('inventory_items', 'unit_price')) {
                $table->decimal('unit_price', 10, 2)->default(0)->after('quantity');
            }
            if (!Schema::hasColumn('inventory_items', 'reorder_level')) {
                $table->decimal('reorder_level', 10, 2)->default(0)->after('unit_price');
            }
            if (!Schema::hasColumn('inventory_items', 'status')) {
                $table->string('status')->default('In Stock')->after('reorder_level');
            }
            
            // Add timestamps if they don't exist
            if (!Schema::hasColumn('inventory_items', 'created_at')) {
                $table->timestamps();
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('inventory_items', function (Blueprint $table) {
            // Drop the columns we added (only if they exist)
            if (Schema::hasColumn('inventory_items', 'item_code')) {
                $table->dropColumn('item_code');
            }
            if (Schema::hasColumn('inventory_items', 'category')) {
                $table->dropColumn('category');
            }
            if (Schema::hasColumn('inventory_items', 'quantity')) {
                $table->dropColumn('quantity');
            }
            if (Schema::hasColumn('inventory_items', 'unit_price')) {
                $table->dropColumn('unit_price');
            }
            if (Schema::hasColumn('inventory_items', 'reorder_level')) {
                $table->dropColumn('reorder_level');
            }
            if (Schema::hasColumn('inventory_items', 'status')) {
                $table->dropColumn('status');
            }
            
            // Drop timestamps if they were added by this migration
            if (Schema::hasColumn('inventory_items', 'created_at')) {
                $table->dropTimestamps();
            }
            
            // Add back the old columns that were removed
            $table->string('sku')->unique()->nullable()->after('id');
            $table->string('unit')->after('name');
            $table->decimal('min_stock', 10, 2)->default(0)->after('unit');
        });
        
        // Recreate the view if it existed (this is optional since we don't know the original structure)
        // DB::statement('CREATE VIEW inventory_stock_levels AS SELECT ...');
    }
};
