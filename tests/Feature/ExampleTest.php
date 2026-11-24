<?php

it('redirige la raíz al inicio y este exige sesión', function () {
    $this->get('/')->assertRedirect('/dashboard');
    $this->get('/dashboard')->assertRedirect('/login');
});
