<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** PUBLICACIÓN / producto (entidad débil del proyecto; subtipos revista, congreso, libro, patente). */
class Producto extends Model
{
    protected $table = 'productos';

    protected $primaryKey = 'id_producto';

    public $timestamps = false;

    public function tipo(): BelongsTo
    {
        return $this->belongsTo(TipoProducto::class, 'id_tipo', 'id_tipo');
    }

    public function proyecto(): BelongsTo
    {
        return $this->belongsTo(Proyecto::class, 'id_proyecto', 'id_proyecto');
    }
}
