document.addEventListener('DOMContentLoaded', function() {
    console.log('EduVioleta - Primer Entregable cargado');
    
    const enlaces = document.querySelectorAll('a');
    enlaces.forEach(function(enlace) {
        enlace.addEventListener('click', function() {
            console.log('Abriendo: ' + this.textContent);
        });
    });
});