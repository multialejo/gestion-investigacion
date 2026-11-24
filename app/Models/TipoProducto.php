<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TipoProducto extends Model
{
    protected $table = 'tipo_pro';

    protected $primaryKey = 'id_tipo';

    public $timestamps = false;
}
