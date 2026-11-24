<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ResumenProyecto extends Model
{
    protected $table = 'resumen_proyecto';

    protected $primaryKey = 'id_proyecto';

    public $timestamps = false;
}
