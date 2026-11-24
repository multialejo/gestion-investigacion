<?php

namespace App\Http\Requests;

use App\Models\Proyecto;
use Illuminate\Foundation\Http\FormRequest;

/**
 * Primera línea de validación (formato y obligatoriedad). Las reglas del
 * negocio (IP doctor, fechas, unicidad) las vuelve a comprobar el SP: si el
 * formulario se saltara, la BD seguiría protegiendo la integridad.
 */
class RegistrarProyectoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', Proyecto::class);
    }

    public function rules(): array
    {
        return [
            'nombre_proyecto' => ['required', 'string', 'max:200'],
            'acronimo' => ['required', 'string', 'max:30', 'alpha_dash'],
            'presupuesto' => ['required', 'numeric', 'min:0', 'max:999999999999'],
            'programa' => ['required', 'string', 'max:150'],
            'descripcion' => ['nullable', 'string', 'max:2000'],
            'inicio_pro' => ['required', 'date'],
            'fin_pro' => ['required', 'date', 'after_or_equal:inicio_pro'],
            'resolucion' => ['required', 'string', 'max:50'],
            'id_investigador_principal' => ['required', 'integer'],
        ];
    }

    public function attributes(): array
    {
        return [
            'nombre_proyecto' => 'nombre del proyecto',
            'acronimo' => 'acrónimo',
            'inicio_pro' => 'fecha de inicio',
            'fin_pro' => 'fecha de fin',
            'resolucion' => 'resolución de aprobación',
            'id_investigador_principal' => 'investigador principal',
        ];
    }
}
