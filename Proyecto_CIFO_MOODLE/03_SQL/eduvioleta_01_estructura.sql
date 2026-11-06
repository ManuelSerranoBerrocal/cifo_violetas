/*
PROYECTO: EduVioleta - Sistema Integral de Gestión Académica y Operativa
CENTRO: CIFO Barcelona La Violeta (Servei Públic d'Ocupació de Catalunya)
AUTOR: Manuel Serrano Berrocal
FECHA: Noviembre 2026
CURSO: IFCD47 - Programación con SQL y bases de datos relacionales
PROFESORA: Rita de la Torre

ESTRUCTURA DEL SCRIPT:
1) CREACIÓN DE LA BASE DE DATOS
2) TABLAS MAESTRAS (Catálogos)
3) TABLAS PRINCIPALES (Usuarios y Jerarquía ISA)
4) TABLAS TRANSACCIONALES (Eventos del negocio)
5) TABLAS DE RELACIÓN / DETALLE (Rompen relaciones N:M)

*/
-- Borra la base de datos anterior si existe (¡CUIDADO: borra todos los datos!)
-- DROP DATABASE IF EXISTS eduvioleta;
-- 1) CREACIÓN DE LA BASE DE DATOS

CREATE DATABASE IF NOT EXISTS eduvioleta
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_general_ci
    DEFAULT ENCRYPTION='N';

USE eduvioleta;

-- =============================================================================
-- 2) TABLAS MAESTRAS (Catálogos - No dependen de tablas de negocio)
-- =============================================================================

CREATE TABLE comunidad_autonoma (
    id_comunidad INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único de la comunidad',
    nombre VARCHAR(100) NOT NULL UNIQUE COMMENT 'Nombre de la comunidad autónoma'
) COMMENT 'Catálogo de comunidades autónomas de España';

CREATE TABLE provincia (
    id_provincia INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único de la provincia',
    nombre VARCHAR(100) NOT NULL COMMENT 'Nombre de la provincia',
    fk_comunidad INT NOT NULL COMMENT 'FK a comunidad_autonoma',
    FOREIGN KEY (fk_comunidad) REFERENCES comunidad_autonoma(id_comunidad)
        ON UPDATE CASCADE ON DELETE RESTRICT
) COMMENT 'Catálogo de provincias';

CREATE TABLE municipio (
    id_municipio INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único del municipio',
    nombre VARCHAR(100) NOT NULL COMMENT 'Nombre del municipio',
    fk_provincia INT NOT NULL COMMENT 'FK a provincia',
    FOREIGN KEY (fk_provincia) REFERENCES provincia(id_provincia)
        ON UPDATE CASCADE ON DELETE RESTRICT
) COMMENT 'Catálogo de municipios';

CREATE TABLE departamento (
    id_departamento INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único del departamento',
    nombre VARCHAR(100) NOT NULL UNIQUE COMMENT 'Nombre del departamento',
    telefono VARCHAR(20) COMMENT 'Teléfono de contacto'
) COMMENT 'Departamentos organizativos del centro';

CREATE TABLE cargo (
    id_cargo INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único del cargo',
    nombre VARCHAR(100) NOT NULL UNIQUE COMMENT 'Nombre del cargo'
) COMMENT 'Catálogo de cargos del personal';

CREATE TABLE familia_profesional (
    id_familia INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único de la familia',
    codigo VARCHAR(20) NOT NULL UNIQUE COMMENT 'Código oficial del SOC',
    nombre VARCHAR(200) NOT NULL COMMENT 'Nombre de la familia profesional'
) COMMENT 'Familias profesionales del catálogo SOC';

CREATE TABLE especialidad (
    id_especialidad INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único de la especialidad',
    codigo VARCHAR(20) NOT NULL UNIQUE COMMENT 'Código oficial de la especialidad',
    nombre VARCHAR(200) NOT NULL COMMENT 'Nombre de la especialidad',
    horas_totales INT NOT NULL CHECK (horas_totales > 0) COMMENT 'Duración total en horas',
    fk_familia INT NOT NULL COMMENT 'FK a familia_profesional',
    FOREIGN KEY (fk_familia) REFERENCES familia_profesional(id_familia)
        ON UPDATE CASCADE ON DELETE RESTRICT
) COMMENT 'Especialidades formativas del SOC';

CREATE TABLE curso (
    id_curso INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único del curso',
    nombre VARCHAR(200) NOT NULL COMMENT 'Nombre del curso genérico',
    fk_especialidad INT NOT NULL COMMENT 'FK a especialidad',
    FOREIGN KEY (fk_especialidad) REFERENCES especialidad(id_especialidad)
        ON UPDATE CASCADE ON DELETE RESTRICT
) COMMENT 'Cursos genéricos del catálogo';

CREATE TABLE aula_fisica (
    id_aula INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único del aula',
    numero_aula VARCHAR(20) NOT NULL UNIQUE COMMENT 'Número identificador del aula',
    capacidad_maxima INT NOT NULL CHECK (capacidad_maxima > 0) COMMENT 'Capacidad máxima de alumnos',
    tiene_proyector BOOLEAN DEFAULT TRUE COMMENT 'Indica si dispone de proyector',
    tiene_ordenadores BOOLEAN DEFAULT TRUE COMMENT 'Indica si dispone de ordenadores',
    estado VARCHAR(20) NOT NULL DEFAULT 'Activa' 
        CHECK (estado IN ('Activa', 'Mantenimiento')) COMMENT 'Estado del aula'
) COMMENT 'Aulas físicas del centro';

-- =============================================================================
-- 3) TABLAS PRINCIPALES (Jerarquía ISA de Usuarios)
-- =============================================================================

CREATE TABLE usuario (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único del usuario',
    dni VARCHAR(20) NOT NULL UNIQUE COMMENT 'DNI o NIE del usuario',
    email VARCHAR(150) NOT NULL UNIQUE COMMENT 'Email institucional',
    nombre VARCHAR(100) NOT NULL COMMENT 'Nombre del usuario',
    apellidos VARCHAR(200) NOT NULL COMMENT 'Apellidos del usuario',
    telefono VARCHAR(20) COMMENT 'Teléfono de contacto',
    calle VARCHAR(200) COMMENT 'Calle de la dirección',
    numero VARCHAR(10) COMMENT 'Número de la dirección',
    piso VARCHAR(10) COMMENT 'Piso de la dirección',
    cp VARCHAR(10) NOT NULL COMMENT 'Código postal',
    fecha_alta DATE NOT NULL DEFAULT (CURRENT_DATE) COMMENT 'Fecha de alta en el sistema',
    estado VARCHAR(20) NOT NULL DEFAULT 'Activo' 
        CHECK (estado IN ('Activo', 'Baja')) COMMENT 'Estado de acceso al sistema',
    fk_municipio INT NOT NULL COMMENT 'FK a municipio',
    FOREIGN KEY (fk_municipio) REFERENCES municipio(id_municipio)
        ON UPDATE CASCADE ON DELETE RESTRICT
) COMMENT 'Tabla principal de usuarios del sistema';

CREATE TABLE alumno (
    id_usuario INT PRIMARY KEY COMMENT 'PK heredada de usuario',
    fecha_nacimiento DATE NOT NULL COMMENT 'Fecha de nacimiento del alumno',
    nivel_estudios_previos VARCHAR(200) COMMENT 'Nivel de estudios previos',
    situacion_laboral VARCHAR(100) COMMENT 'Situación laboral actual',
    empresa_trabajo VARCHAR(200) COMMENT 'Empresa donde trabaja (si aplica)',
    estado_academico VARCHAR(50) NOT NULL DEFAULT 'Regular'
        CHECK (estado_academico IN ('Regular', 'Bloqueado_Pendiente', 'Sancionado'))
        COMMENT 'Estado académico del alumno',
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE
) COMMENT 'Subentidad ALUMNO (Jerarquía ISA)';

CREATE TABLE staff (
    id_usuario INT PRIMARY KEY COMMENT 'PK heredada de usuario',
    fecha_ingreso_centro DATE NOT NULL COMMENT 'Fecha de ingreso al centro',
    tipo_contrato VARCHAR(100) NOT NULL COMMENT 'Tipo de contrato',
    horas_semanales INT NOT NULL CHECK (horas_semanales BETWEEN 0 AND 40) 
        COMMENT 'Horas semanales de trabajo',
    fk_departamento INT NOT NULL COMMENT 'FK a departamento',
    fk_cargo INT NOT NULL COMMENT 'FK a cargo',
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (fk_departamento) REFERENCES departamento(id_departamento)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (fk_cargo) REFERENCES cargo(id_cargo)
        ON UPDATE CASCADE ON DELETE RESTRICT
) COMMENT 'Subentidad STAFF (Jerarquía ISA)';

CREATE TABLE docente (
    id_usuario INT PRIMARY KEY COMMENT 'PK heredada de staff',
    especialidad_docente VARCHAR(200) NOT NULL COMMENT 'Especialidad docente',
    anos_experiencia INT NOT NULL CHECK (anos_experiencia >= 0) 
        COMMENT 'Años de experiencia docente',
    FOREIGN KEY (id_usuario) REFERENCES staff(id_usuario) ON DELETE CASCADE
) COMMENT 'Subentidad DOCENTE (Jerarquía ISA)';

CREATE TABLE administrativo (
    id_usuario INT PRIMARY KEY COMMENT 'PK heredada de staff',
    cargo_administrativo VARCHAR(100) NOT NULL COMMENT 'Cargo administrativo',
    despacho VARCHAR(50) COMMENT 'Número de despacho',
    FOREIGN KEY (id_usuario) REFERENCES staff(id_usuario) ON DELETE CASCADE
) COMMENT 'Subentidad ADMINISTRATIVO (Jerarquía ISA)';

CREATE TABLE director (
    id_usuario INT PRIMARY KEY COMMENT 'PK heredada de staff',
    cargo_directivo VARCHAR(100) NOT NULL COMMENT 'Cargo directivo',
    despacho_principal VARCHAR(50) COMMENT 'Despacho principal',
    FOREIGN KEY (id_usuario) REFERENCES staff(id_usuario) ON DELETE CASCADE
) COMMENT 'Subentidad DIRECTOR (Jerarquía ISA)';

-- =============================================================================
-- 4) TABLAS TRANSACCIONALES (Eventos del negocio)
-- =============================================================================

CREATE TABLE convocatoria (
    id_convocatoria INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único de la convocatoria',
    codigo_convocatoria VARCHAR(50) NOT NULL UNIQUE COMMENT 'Código oficial de la convocatoria',
    fecha_inicio DATE NOT NULL COMMENT 'Fecha de inicio de la convocatoria',
    fecha_fin DATE NOT NULL COMMENT 'Fecha de fin de la convocatoria',
    modalidad VARCHAR(20) NOT NULL 
        CHECK (modalidad IN ('Presencial', 'Teleformación')) COMMENT 'Modalidad de enseñanza',
    horario VARCHAR(20) NOT NULL 
        CHECK (horario IN ('Mañana', 'Tarde')) COMMENT 'Horario de la convocatoria',
    plazas INT NOT NULL CHECK (plazas >= 0) COMMENT 'Número de plazas disponibles',
    es_certificado BOOLEAN DEFAULT FALSE COMMENT 'Indica si otorga Certificado Profesional',
    estado VARCHAR(20) NOT NULL DEFAULT 'Planificada'
        CHECK (estado IN ('Planificada', 'Activa', 'Finalizada', 'Cancelada'))
        COMMENT 'Estado de la convocatoria',
    fk_curso INT NOT NULL COMMENT 'FK a curso',
    fk_aula INT COMMENT 'FK a aula_fisica (NULL en teleformación)',
    fk_docente_responsable INT NOT NULL COMMENT 'FK a docente responsable',
    FOREIGN KEY (fk_curso) REFERENCES curso(id_curso)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (fk_aula) REFERENCES aula_fisica(id_aula)
        ON UPDATE CASCADE ON DELETE SET NULL,
    FOREIGN KEY (fk_docente_responsable) REFERENCES docente(id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    -- La fecha fin debe ser posterior a la fecha inicio
	CHECK (fecha_fin >= fecha_inicio)
) COMMENT 'Convocatorias concretas de formación';

CREATE TABLE sesion (
    id_sesion INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único de la sesión',
    fecha DATE NOT NULL COMMENT 'Fecha de la sesión',
    hora_inicio TIME NOT NULL COMMENT 'Hora de inicio',
    hora_fin TIME NOT NULL COMMENT 'Hora de fin',
    estado_sesion VARCHAR(20) NOT NULL DEFAULT 'Abierta'
        CHECK (estado_sesion IN ('Abierta', 'Cerrada')) COMMENT 'Estado administrativo',
    fecha_cierre DATETIME COMMENT 'Fecha y hora del cierre administrativo',
    fk_convocatoria INT NOT NULL COMMENT 'FK a convocatoria',
    fk_aula INT COMMENT 'FK a aula_fisica (NULL en teleformación)',
    fk_docente INT NOT NULL COMMENT 'FK a docente que imparte',
    fk_administrativo_cierre INT COMMENT 'FK a administrativo que cierra (NULL si abierta)',
    FOREIGN KEY (fk_convocatoria) REFERENCES convocatoria(id_convocatoria)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (fk_aula) REFERENCES aula_fisica(id_aula)
        ON UPDATE CASCADE ON DELETE SET NULL,
    FOREIGN KEY (fk_docente) REFERENCES docente(id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (fk_administrativo_cierre) REFERENCES administrativo(id_usuario)
        ON UPDATE CASCADE ON DELETE SET NULL,
    -- La hora fin debe ser posterior a la hora inicio
    CHECK (hora_fin > hora_inicio)
) COMMENT 'Sesiones de clase de las convocatorias';

CREATE TABLE justificacion (
    id_justificacion INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único',
    tipo_motivo VARCHAR(20) NOT NULL 
        CHECK (tipo_motivo IN ('Médica', 'Personal', 'Laboral'))
        COMMENT 'Tipo de motivo de la justificación',
    archivo_adjunto VARCHAR(255) COMMENT 'Ruta del archivo adjunto',
    estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente'
        CHECK (estado IN ('Pendiente', 'Aprobada', 'Rechazada'))
        COMMENT 'Estado de la justificación',
    fecha_solicitud DATE NOT NULL DEFAULT (CURRENT_DATE) COMMENT 'Fecha de solicitud',
    fecha_revision DATE COMMENT 'Fecha de revisión administrativa',
    comentario_revision TEXT COMMENT 'Comentario del administrativo revisor',
    fk_alumno INT NOT NULL COMMENT 'FK a alumno',
    fk_convocatoria INT NOT NULL COMMENT 'FK a convocatoria',
    fk_administrativo_revisor INT COMMENT 'FK a administrativo revisor (NULL si pendiente)',
    FOREIGN KEY (fk_alumno) REFERENCES alumno(id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (fk_convocatoria) REFERENCES convocatoria(id_convocatoria)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (fk_administrativo_revisor) REFERENCES administrativo(id_usuario)
        ON UPDATE CASCADE ON DELETE SET NULL
) COMMENT 'Justificaciones de inasistencias de alumnos';

CREATE TABLE sancion (
    id_sancion INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único',
    fecha_inicio DATE NOT NULL COMMENT 'Fecha de inicio de la sanción',
    fecha_fin DATE NOT NULL COMMENT 'Fecha de fin de la sanción',
    motivo TEXT NOT NULL COMMENT 'Motivo de la sanción',
    estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente'
        CHECK (estado IN ('Pendiente', 'Activa', 'Cumplida', 'Anulada'))
        COMMENT 'Estado de la sanción',
    fk_alumno INT NOT NULL COMMENT 'FK a alumno',
    fk_convocatoria INT NOT NULL COMMENT 'FK a convocatoria que originó la sanción',
    FOREIGN KEY (fk_alumno) REFERENCES alumno(id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (fk_convocatoria) REFERENCES convocatoria(id_convocatoria)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    -- La fecha fin debe ser posterior a la fecha inicio
    CHECK (fecha_fin >= fecha_inicio)
) COMMENT 'Sanciones aplicadas a alumnos';

CREATE TABLE modulo (
    id_modulo INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único del módulo',
    nombre VARCHAR(200) NOT NULL COMMENT 'Nombre del módulo',
    descripcion TEXT COMMENT 'Descripción del módulo',
    fk_convocatoria INT NOT NULL COMMENT 'FK a convocatoria',
    FOREIGN KEY (fk_convocatoria) REFERENCES convocatoria(id_convocatoria)
        ON UPDATE CASCADE ON DELETE CASCADE
) COMMENT 'Módulos temáticos de las convocatorias (Campus Virtual)';

CREATE TABLE material (
    id_material INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único del material',
    titulo VARCHAR(200) NOT NULL COMMENT 'Título del material',
    tipo VARCHAR(20) NOT NULL 
        CHECK (tipo IN ('PDF', 'Enlace', 'Tarea', 'Examen'))
        COMMENT 'Tipo de material',
    fecha_limite DATE COMMENT 'Fecha límite de entrega',
    fk_modulo INT NOT NULL COMMENT 'FK a módulo',
    fk_docente_responsable INT NOT NULL COMMENT 'FK a docente responsable',
    FOREIGN KEY (fk_modulo) REFERENCES modulo(id_modulo)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (fk_docente_responsable) REFERENCES docente(id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) COMMENT 'Materiales del campus virtual';

CREATE TABLE anuncio (
    id_anuncio INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único del anuncio',
    titulo VARCHAR(200) NOT NULL COMMENT 'Título del anuncio',
    contenido TEXT NOT NULL COMMENT 'Contenido del anuncio',
    es_urgente BOOLEAN DEFAULT FALSE COMMENT 'Indica si es urgente',
    fecha_publicacion DATETIME NOT NULL DEFAULT (CURRENT_TIMESTAMP) 
        COMMENT 'Fecha de publicación',
    fk_usuario_publica INT NOT NULL COMMENT 'FK a usuario que publica',
    FOREIGN KEY (fk_usuario_publica) REFERENCES usuario(id_usuario)
        ON UPDATE CASCADE ON DELETE CASCADE
) COMMENT 'Anuncios publicados por los usuarios';

CREATE TABLE incidencia (
    id_incidencia INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único',
    descripcion TEXT NOT NULL COMMENT 'Descripción de la incidencia',
    prioridad VARCHAR(20) NOT NULL 
        CHECK (prioridad IN ('Baja', 'Media', 'Alta'))
        COMMENT 'Prioridad de la incidencia',
    estado VARCHAR(20) NOT NULL DEFAULT 'Abierta'
        CHECK (estado IN ('Abierta', 'En proceso', 'Cerrada'))
        COMMENT 'Estado de la incidencia',
    fecha DATETIME NOT NULL DEFAULT (CURRENT_TIMESTAMP) COMMENT 'Fecha de reporte',
    fk_usuario_reporta INT NOT NULL COMMENT 'FK a usuario que reporta',
    fk_aula INT NOT NULL COMMENT 'FK a aula afectada',
    FOREIGN KEY (fk_usuario_reporta) REFERENCES usuario(id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (fk_aula) REFERENCES aula_fisica(id_aula)
        ON UPDATE CASCADE ON DELETE RESTRICT
) COMMENT 'Incidencias reportadas en las aulas';

-- =============================================================================
-- 5) TABLAS DE RELACIÓN / DETALLE (Rompen relaciones N:M)
-- =============================================================================

CREATE TABLE matricula (
    id_matricula INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único',
    fecha_matricula DATE NOT NULL DEFAULT (CURRENT_DATE) COMMENT 'Fecha de matrícula',
    estado VARCHAR(20) NOT NULL DEFAULT 'Activa'
        CHECK (estado IN ('Activa', 'Completada', 'Abandonada'))
        COMMENT 'Estado de la matrícula',
    calificacion_final DECIMAL(5,2) 
        CHECK (calificacion_final BETWEEN 0 AND 10)
        COMMENT 'Calificación final (0-10)',
    fk_alumno INT NOT NULL COMMENT 'FK a alumno',
    fk_convocatoria INT NOT NULL COMMENT 'FK a convocatoria',
    FOREIGN KEY (fk_alumno) REFERENCES alumno(id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (fk_convocatoria) REFERENCES convocatoria(id_convocatoria)
        ON UPDATE CASCADE ON DELETE RESTRICT
) COMMENT 'Matrículas de alumnos en convocatorias';

CREATE TABLE firma_entrada (
    id_firma_entrada INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único',
    hora_firma DATETIME NOT NULL DEFAULT (CURRENT_TIMESTAMP) 
        COMMENT 'Hora exacta de la firma',
    fk_sesion INT NOT NULL COMMENT 'FK a sesión',
    fk_alumno INT NOT NULL COMMENT 'FK a alumno',
    FOREIGN KEY (fk_sesion) REFERENCES sesion(id_sesion)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (fk_alumno) REFERENCES alumno(id_usuario)
        ON UPDATE CASCADE ON DELETE CASCADE,
    UNIQUE (fk_sesion, fk_alumno) COMMENT 'Un alumno solo puede firmar entrada una vez por sesión'
) COMMENT 'Firmas de entrada de los alumnos (Lista 1)';

CREATE TABLE firma_salida (
    id_firma_salida INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único',
    hora_firma DATETIME NOT NULL DEFAULT (CURRENT_TIMESTAMP) 
        COMMENT 'Hora exacta de la firma',
    fk_sesion INT NOT NULL COMMENT 'FK a sesión',
    fk_alumno INT NOT NULL COMMENT 'FK a alumno',
    FOREIGN KEY (fk_sesion) REFERENCES sesion(id_sesion)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (fk_alumno) REFERENCES alumno(id_usuario)
        ON UPDATE CASCADE ON DELETE CASCADE,
    UNIQUE (fk_sesion, fk_alumno) COMMENT 'Un alumno solo puede firmar salida una vez por sesión'
) COMMENT 'Firmas de salida de los alumnos (Lista 2)';

CREATE TABLE entrega (
    id_entrega INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único',
    fecha_entrega DATETIME NOT NULL DEFAULT (CURRENT_TIMESTAMP) 
        COMMENT 'Fecha y hora de entrega',
    calificacion DECIMAL(3,2) 
        CHECK (calificacion BETWEEN 0 AND 10)
        COMMENT 'Calificación de la entrega (0-10)',
    comentario TEXT COMMENT 'Comentario del docente evaluador',
    fk_material INT NOT NULL COMMENT 'FK a material',
    fk_alumno INT NOT NULL COMMENT 'FK a alumno',
    fk_docente_evaluador INT NOT NULL COMMENT 'FK a docente evaluador',
    FOREIGN KEY (fk_material) REFERENCES material(id_material)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (fk_alumno) REFERENCES alumno(id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (fk_docente_evaluador) REFERENCES docente(id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) COMMENT 'Entregas de materiales por parte de los alumnos';

-- Para confirmar que todo está bien
SHOW TABLES;

-- Deberías ver 27 tablas listadas
SELECT COUNT(*) AS total_tablas FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'eduvioleta';



