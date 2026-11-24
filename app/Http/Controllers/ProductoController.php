<?php

namespace App\Http\Controllers;

use App\Database\Procedimientos\ReclasificarProducto;
use App\Database\Procedimientos\RegistrarProducto;
use App\Facades\Procedimientos;
use App\Models\Producto;
use App\Models\Proyecto;
use App\Productos\FabricaEstrategiaProducto;
use Illuminate\Http\Request;

/**
 * El controlador no conoce los tipos de producto: pide a la fábrica la
 * estrategia del tipo elegido y delega en ella campos, validación y
 * parámetros del SP (Strategy + Factory Method).
 */
class ProductoController extends Controller
{
    public function create(Request $request, Proyecto $proyecto)
    {
        $this->authorize('modificar', $proyecto);
        $estrategia = FabricaEstrategiaProducto::para((int) $request->query('tipo', 1));

        return view('productos.form', [
            'proyecto' => $proyecto,
            'producto' => null,
            'estrategia' => $estrategia,
            'estrategias' => FabricaEstrategiaProducto::todas(),
        ]);
    }

    public function store(Request $request, Proyecto $proyecto)
    {
        $this->authorize('modificar', $proyecto);
        $estrategia = FabricaEstrategiaProducto::para((int) $request->input('tipo'));

        $datos = $request->validate(['titulo' => ['required', 'string', 'max:255']] + $estrategia->reglas());

        Procedimientos::ejecutar(new RegistrarProducto($proyecto->id_proyecto, $estrategia, $datos));

        return redirect()->route('proyectos.show', $proyecto)
            ->with('status', "{$estrategia->etiqueta()} registrada por sp_registrar_producto_transaccional.");
    }

    public function editTipo(Request $request, Producto $producto)
    {
        $this->authorize('modificar', $producto->proyecto);
        $estrategia = FabricaEstrategiaProducto::para((int) $request->query('tipo', $producto->id_tipo === 1 ? 2 : 1));

        return view('productos.form', [
            'proyecto' => $producto->proyecto,
            'producto' => $producto,
            'estrategia' => $estrategia,
            'estrategias' => FabricaEstrategiaProducto::todas(),
        ]);
    }

    public function reclasificar(Request $request, Producto $producto)
    {
        $this->authorize('modificar', $producto->proyecto);
        $estrategia = FabricaEstrategiaProducto::para((int) $request->input('tipo'));
        $datos = $request->validate($estrategia->reglas());

        Procedimientos::ejecutar(new ReclasificarProducto($producto->id_producto, $estrategia, $datos));

        return redirect()->route('proyectos.show', $producto->id_proyecto)
            ->with('status', "Producto reclasificado como {$estrategia->etiqueta()} por sp_reclasificar_producto_transaccional.");
    }
}
