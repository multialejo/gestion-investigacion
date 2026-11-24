<?php

afterEach(fn () => limpiarProyectosDePrueba());

function ultimaAuditoria(): object
{
    return negocio()->table('auditoria_operaciones')->orderByDesc('id_auditoria')->first();
}

it('registra un proyecto con sp_registrar_proyecto_transaccional (proyecto + IP como Director + resumen)', function () {
    $p = proyectoDePrueba();

    expect($p)->not->toBeNull();
    expect(negocio()->table('proyecto_profesor')->where('id_proyecto', $p->id_proyecto)->first())
        ->id_profesor->toBe($p->id_investigador_principal)
        ->cargo->toBe('Director');
    expect(negocio()->table('resumen_proyecto')->where('id_proyecto', $p->id_proyecto)->value('total_productos'))->toBe(0);
    expect(ultimaAuditoria()->resultado)->toStartWith('EXITOSO');
});

it('el SP rechaza un investigador principal no doctor, revierte y lo audita', function () {
    $noDoctor = negocio()->table('profesores')->where('tipo', 'no_doctor')->value('id_profesor');
    $datos = datosProyecto(['id_investigador_principal' => $noDoctor]);

    $this->actingAs(usuarioCon('secretaria'))->from('/proyectos/nuevo')->post('/proyectos', $datos)
        ->assertRedirect('/proyectos/nuevo')
        ->assertSessionHasErrors(['bd' => 'Transaccion revertida: El investigador principal debe ser doctor.']);

    expect(negocio()->table('proyecto_investigacion')->where('acronimo', $datos['acronimo'])->exists())->toBeFalse();
    expect(ultimaAuditoria()->resultado)->toBe('FALLIDO - El investigador principal debe ser doctor.');
});

it('la validación de Laravel detiene datos mal formados antes de llegar al SP', function () {
    $antes = negocio()->table('auditoria_operaciones')->count();

    $this->actingAs(usuarioCon('secretaria'))
        ->post('/proyectos', datosProyecto(['acronimo' => 'con espacios!', 'fin_pro' => '2026-01-01']))
        ->assertSessionHasErrors(['acronimo', 'fin_pro']);

    expect(negocio()->table('auditoria_operaciones')->count())->toBe($antes); // el SP ni se llamó
});

it('controla la prórroga: máximo 3 meses y una sola vez', function () {
    $p = proyectoDePrueba();
    $this->actingAs(usuarioCon('secretaria'));

    $this->post("/proyectos/{$p->id_proyecto}/prorroga", ['nueva_fecha_fin' => '2028-06-30'])
        ->assertSessionHasErrors(['bd' => 'Transaccion revertida: La prorroga no puede exceder los 3 meses sobre la fecha de fin.']);
    $this->post("/proyectos/{$p->id_proyecto}/prorroga", ['nueva_fecha_fin' => '2028-02-15'])
        ->assertSessionHasNoErrors();
    $this->post("/proyectos/{$p->id_proyecto}/prorroga", ['nueva_fecha_fin' => '2028-03-01'])
        ->assertSessionHasErrors(['bd' => 'Transaccion revertida: El proyecto ya tiene una prorroga registrada.']);

    expect(negocio()->table('proyecto_investigacion')->where('id_proyecto', $p->id_proyecto)->value('prorroga'))->toBe('2028-02-15');
});

it('ejecuta los reportes de consulta (sp_ca* y sp_cm*)', function (string $codigo) {
    $this->actingAs(usuarioCon('coordinador'))->get("/reportes/{$codigo}")
        ->assertOk()
        ->assertViewHas('filas', fn ($filas) => $filas->isNotEmpty());
})->with(['ca1', 'ca2', 'ca3', 'ca4', 'ca5', 'cm1', 'cm2', 'cm3', 'cm4', 'cm5']);

it('no acepta nombres de procedimiento fuera de la lista blanca', function () {
    $this->actingAs(usuarioCon('coordinador'))->get('/reportes/sp_registrar_proyecto_transaccional')->assertNotFound();
});
