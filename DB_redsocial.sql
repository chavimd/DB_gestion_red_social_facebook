-- =============================================================
-- SCRIPT FINAL COMPLETO: RED SOCIAL (Unidad 1)
-- INCLUYE: Creación de tablas, Funciones, Triggers y CARGA MASIVA DE DATOS
-- =============================================================

-- 1. LIMPIEZA INICIAL (¡CUIDADO! BORRA TODO LO ANTERIOR)
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

-- =============================================================
-- PARTE 1: CREACIÓN DE TABLAS (DDL)
-- =============================================================

CREATE TABLE genero (id_genero int PRIMARY KEY, genero varchar(40));
CREATE TABLE pais (id_pais int PRIMARY KEY, nombre varchar(50));
CREATE TABLE categorias (id_categoria int PRIMARY KEY, categoria varchar(70));
CREATE TABLE tipo_publicacion (id_tipo int PRIMARY KEY, tipo_publicacion varchar(50));
CREATE TABLE tipo_reacciones (id_tipo_reaccion int PRIMARY KEY, tipo_reaccion varchar(40));

CREATE TABLE tiempo (
    id_t int PRIMARY KEY, 
    fecha date NOT NULL, 
    anio int NOT NULL, 
    mes int NOT NULL, 
    dia int NOT NULL
);

CREATE TABLE conversaciones (
    id_conver int PRIMARY KEY, 
    fecha_inicio date NOT NULL
);

-- Tabla Usuarios
CREATE TABLE usuarios (
    id_user int PRIMARY KEY,
    nombres varchar(40) NOT NULL,
    apellidos varchar(40) NOT NULL,
    email varchar(40) NOT NULL,
    fecha_nacimiento date NOT NULL,
    fecha_registro date,
    id_genero int,
    id_pais int,
    FOREIGN KEY (id_genero) REFERENCES genero (id_genero),
    FOREIGN KEY (id_pais) REFERENCES pais (id_pais)
);

-- Tablas dependientes de usuarios
CREATE TABLE amistades (
    id_amistad int PRIMARY KEY,
    fecha_amistad date NOT NULL,
    id_user_1 int NOT NULL,
    id_user_2 int NOT NULL,
    FOREIGN KEY (id_user_1) REFERENCES usuarios (id_user),
    FOREIGN KEY (id_user_2) REFERENCES usuarios (id_user)
);

CREATE TABLE fotos (
    id_foto int PRIMARY KEY,
    id_user int NOT NULL,
    url varchar(100) NOT NULL,
    descripcion varchar(100) NOT NULL,
    fecha_subida date,
    FOREIGN KEY (id_user) REFERENCES usuarios (id_user)
);

CREATE TABLE videos (
    id_video int PRIMARY KEY,
    id_user int NOT NULL,
    url varchar(100) NOT NULL,
    descripcion varchar(100) NOT NULL,
    fecha_subida date NOT NULL,
    FOREIGN KEY (id_user) REFERENCES usuarios(id_user)
);

CREATE TABLE sesiones (
    id_sesion int PRIMARY KEY,
    id_user int NOT NULL,
    fecha_inicio date NOT NULL,
    fecha_fin date NOT NULL,
    ip varchar(60),
    FOREIGN KEY (id_user) REFERENCES usuarios (id_user)
);

CREATE TABLE mensajes (
    id_mensaje int PRIMARY KEY,
    id_conver int NOT NULL,
    id_user_emisor int NOT NULL,
    id_user_receptor int NOT NULL,
    contenido varchar(500) NOT NULL,
    fecha_envio date NOT NULL,
    FOREIGN KEY (id_conver) REFERENCES conversaciones(id_conver),
    FOREIGN KEY (id_user_emisor) REFERENCES usuarios(id_user),
    FOREIGN KEY (id_user_receptor) REFERENCES usuarios(id_user)
);

CREATE TABLE paginas (
    id_page int PRIMARY KEY,
    nombre varchar(50) NOT NULL,
    descripcion varchar(100) NOT NULL,
    id_categoria int NOT NULL,
    id_user int NOT NULL,
    fecha_creacion date NOT NULL,
    FOREIGN KEY (id_user) REFERENCES usuarios(id_user),
    FOREIGN KEY (id_categoria) REFERENCES categorias (id_categoria)
);

CREATE TABLE seguidores_paginas (
    id_user_page int PRIMARY KEY,
    id_user int NOT NULL,
    paginas_id_page int NOT NULL,
    fecha_seguimiento date,
    FOREIGN KEY (id_user) REFERENCES usuarios (id_user),
    FOREIGN KEY (paginas_id_page) REFERENCES paginas (id_page)
);

-- Publicaciones y Reacciones
CREATE TABLE publicaciones (
    id_publicacion int PRIMARY KEY,
    id_user int NOT NULL,
    id_tipo int NOT NULL,
    contenido varchar(255) NOT NULL,
    fecha_publicacion date NOT NULL,
    cantidad int NOT NULL DEFAULT 0,
    FOREIGN KEY (id_user) REFERENCES usuarios(id_user),
    FOREIGN KEY (id_tipo) REFERENCES tipo_publicacion(id_tipo)
);

CREATE TABLE publicaciones_pagina (
    id_pub_page int PRIMARY KEY,
    id_page int NOT NULL,
    contenido varchar(150) NOT NULL,
    id_tipo int NOT NULL,
    fecha_publicacion date,
    FOREIGN KEY (id_page) REFERENCES paginas (id_page),
    FOREIGN KEY (id_tipo) REFERENCES tipo_publicacion (id_tipo)
);

CREATE TABLE comentarios_publicaciones (
    id_comentario int PRIMARY KEY,
    id_user int NOT NULL,
    id_publicacion int NOT NULL,
    contenido varchar(100) NOT NULL,
    fecha_comentario date NOT NULL,
    FOREIGN KEY (id_user) REFERENCES usuarios(id_user),
    FOREIGN KEY (id_publicacion) REFERENCES publicaciones(id_publicacion)
);

CREATE TABLE comentarios_publi_pages (
    id_comentario int PRIMARY KEY,
    id_user int NOT NULL,
    id_pub_page int NOT NULL,
    contenido varchar(100) NOT NULL,
    fecha_cmentario date NOT NULL,
    FOREIGN KEY (id_user) REFERENCES usuarios(id_user),
    FOREIGN KEY (id_pub_page) REFERENCES publicaciones_pagina(id_pub_page)
);

CREATE TABLE reacciones (
    id_reaccion int PRIMARY KEY,
    id_user int NOT NULL,
    id_publicacion int NOT NULL,
    id_tipo_reaccion int NOT NULL,
    fecha_reaccion date NOT NULL,
    FOREIGN KEY (id_user) REFERENCES usuarios (id_user),
    FOREIGN KEY (id_publicacion) REFERENCES publicaciones (id_publicacion),
    FOREIGN KEY (id_tipo_reaccion) REFERENCES tipo_reacciones(id_tipo_reaccion)
);

CREATE TABLE reacciones_publicaciones_page (
    id_reaccion int PRIMARY KEY,
    id_user int NOT NULL,
    id_pub_page int NOT NULL,
    id_tipo_reaccion int NOT NULL,
    fecha_reaccion date NOT NULL,
    FOREIGN KEY (id_user) REFERENCES usuarios (id_user),
    FOREIGN KEY (id_pub_page) REFERENCES publicaciones_pagina (id_pub_page),
    FOREIGN KEY (id_tipo_reaccion) REFERENCES tipo_reacciones(id_tipo_reaccion)
);

-- =============================================================
-- PARTE 2: FUNCIONES Y TRIGGERS (PL/pgSQL) - ¡OBLIGATORIO!
-- =============================================================

-- 2.1 Trigger: Actualizar Cantidad de Reacciones Automáticamente
CREATE OR REPLACE FUNCTION actualizar_cantidad_reacciones()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE publicaciones
    SET cantidad = cantidad + 1
    WHERE id_publicacion = NEW.id_publicacion;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_reaccion_insert
AFTER INSERT ON reacciones
FOR EACH ROW
EXECUTE FUNCTION actualizar_cantidad_reacciones();

-- 2.2 Función: Registrar Usuario (Evita duplicados)
CREATE OR REPLACE FUNCTION registrar_usuario(
    p_nombres VARCHAR, p_apellidos VARCHAR, p_email VARCHAR, 
    p_fecha_nacimiento DATE, p_id_genero INT, p_id_pais INT
) RETURNS VOID AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM usuarios WHERE email = p_email) THEN
        RAISE EXCEPTION 'El correo % ya está registrado', p_email;
    ELSE
        INSERT INTO usuarios (id_user, nombres, apellidos, email, fecha_nacimiento, fecha_registro, id_genero, id_pais)
        VALUES ((SELECT COALESCE(MAX(id_user),0)+1 FROM usuarios), p_nombres, p_apellidos, p_email, p_fecha_nacimiento, CURRENT_DATE, p_id_genero, p_id_pais);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 2.3 Función: Contar comentarios (Auditoría)
CREATE OR REPLACE FUNCTION contar_comentarios_usuario(
    p_usuario_id INT, p_fecha_desde DATE, p_fecha_hasta DATE
) RETURNS INT AS $$
DECLARE
    num_comentarios INT;
BEGIN
    SELECT COUNT(*) INTO num_comentarios FROM comentarios_publicaciones
    WHERE id_user = p_usuario_id AND fecha_comentario BETWEEN p_fecha_desde AND p_fecha_hasta;
    RETURN num_comentarios;
END;
$$ LANGUAGE plpgsql;

-- =============================================================
-- PARTE 3: CARGA MASIVA DE DATOS (DML) - ¡COMPLETO!
-- =============================================================

INSERT INTO genero (id_genero, genero) VALUES (1, 'Masculino'), (2, 'Femenino'), (3, 'No binario');

INSERT INTO pais (id_pais, nombre) VALUES 
(1, 'Bolivia'), (2, 'Argentina'), (3, 'Chile'), (4, 'Brasil'), (5, 'Perú'), 
(6, 'Colombia'), (7, 'México'), (8, 'España'), (9, 'Estados Unidos'), (10, 'Canadá');

-- USUARIOS (150 registros corregidos)
INSERT INTO usuarios (id_user, nombres, apellidos, email, fecha_nacimiento, fecha_registro, id_genero, id_pais) VALUES 
(1, 'Juan', 'Pérez', 'juanp@gmail.com', '1995-05-15', '2024-01-10', 1, 1),
(2, 'Ana', 'García', 'anag@gmail.com', '1998-07-20', '2024-01-11', 2, 2),
(3, 'Luis', 'Ramos', 'luisr@example.com', '2000-02-10', '2024-01-15', 1, 3),
(4, 'Esmeralda', 'Medina', 'esme@gamil.com', '2005-02-01', '2020-01-15', 2, 1),
(5, 'Lucía ', 'Vargas','luci@gmail.com', '2005-02-03', '2020-01-15', 2, 1),
(6, 'Carlos ', 'López', 'carlos@gmail.com' , '2004-02-13', '2021-01-15', 1, 4),
(7, 'Sandra', 'Arce ','sandi@gmail.com', '2005-02-03', '2020-01-15', 2, 1),
(8, 'Pedro', 'Comercio', 'pedro@gmail.com', '2005-02-03', '2020-01-15', 1, 5),
(9, 'Teresa', 'Guzmán', 'ter@gmail.com', '2005-02-04', '2020-02-15', 2, 5),
(10, 'Mario', 'Central', 'mario@gmail.com' , '2004-02-14', '2021-01-15', 1, 5),
(11, 'Sofía', 'Castro', 'sofia@gmail.com' , '2004-02-23', '2021-01-15', 2, 4),
(12, 'Ramiro', 'Soto' ,'rami@gmail.com' , '2004-02-13', '2021-01-15', 1, 4),
(13, 'Carmen', ' Ríos', 'carmen@gmail.com' , '2004-02-11', '2021-01-15', 2, 4),
(14, 'Miguel', 'Torres', 'miguelt@email.com', '1990-11-25', '2023-03-01', 1, 6),
(15, 'Valeria', 'Díaz', 'valeriad@email.com', '1992-01-05', '2023-03-05', 2, 7),
(16, 'Roberto', 'Silva', 'robertos@email.com', '1988-09-10', '2023-03-10', 1, 8),
(17, 'Andrea', 'Vega', 'andreav@email.com', '1997-04-18', '2023-03-12', 3, 9),
(18, 'Fernando', 'Ruiz', 'fernandor@email.com', '1985-12-03', '2023-03-15', 1, 10),
(19, 'Laura', 'Gómez', 'laurag@email.com', '1993-08-22', '2023-03-18', 2, 1),
(20, 'David', 'Martínez', 'davidm@email.com', '1991-06-30', '2023-03-20', 1, 2),
(21, 'Elena', 'Moreno', 'elenam@email.com', '1996-02-14', '2023-03-22', 2, 3),
(22, 'Pablo', 'Jiménez', 'pabloj@email.com', '1989-10-01', '2023-03-25', 3, 4),
(23, 'Sofía', 'Hernández', 'sofiah@email.com', '1994-07-07', '2023-03-28', 2, 5),
(24, 'Diego', 'González', 'diegog@email.com', '1987-03-19', '2023-04-01', 1, 6),
(25, 'Gabriela', 'Rodríguez', 'gabrielar@email.com', '1999-01-28', '2023-04-03', 2, 7),
(26, 'Daniel', 'Díaz', 'danield@email.com', '1986-05-12', '2023-04-05', 1, 8),
(27, 'Carolina', 'Santos', 'carolinas@email.com', '1990-11-04', '2023-04-07', 2, 9),
(28, 'Andrés', 'Castro', 'andresc@email.com', '1995-09-16', '2023-04-10', 3, 10),
(29, 'Natalia', 'Ortega', 'nataliao@email.com', '1992-04-23', '2023-04-12', 2, 1),
(30, 'Ricardo', 'Rubio', 'ricardor@email.com', '1984-02-29', '2023-04-15', 1, 2),
(31, 'Marcela', 'Prieto', 'marcelap@email.com', '1998-06-08', '2023-04-18', 2, 3),
(32, 'Jorge', 'Serrano', 'jorges@email.com', '1983-10-11', '2023-04-20', 1, 4),
(33, 'Camila', 'Vidal', 'camilav@email.com', '1997-03-02', '2023-04-22', 2, 5),
(34, 'Cristian', 'Molina', 'cristianm@email.com', '1982-07-27', '2023-04-25', 1, 6),
(35, 'Adriana', 'Navarro', 'adrianan@email.com', '1994-12-09', '2023-04-28', 2, 7),
(36, 'Javier', 'Delgado', 'javierd@email.com', '1981-01-13', '2023-05-01', 1, 8),
(37, 'Alejandra', 'Ibañez', 'alejandrai@email.com', '1991-05-01', '2023-05-03', 2, 9),
(38, 'Sergio', 'Guerrero', 'sergiog@email.com', '1980-08-06', '2023-05-05', 1, 10),
(39, 'Diana', 'Ferrer', 'dianaf@email.com', '1996-10-17', '2023-05-07', 2, 1),
(40, 'Federico', 'Blando', 'federico@email.com', '1989-03-24', '2023-05-10', 1, 2),
(41, 'Paula', 'Gil', 'paulag@email.com', '1993-11-02', '2023-05-12', 2, 3),
(42, 'Gonzalo', 'Reyes', 'gonzalor@email.com', '1987-06-15', '2023-05-15', 1, 4),
(43, 'Victoria', 'Cruz', 'victoriac@email.com', '1990-02-28', '2023-05-18', 2, 5),
(44, 'Manuel', 'Herrera', 'manuelh@email.com', '1985-09-07', '2023-05-20', 1, 6),
(45, 'Jimena', 'Flores', 'jimenaf@email.com', '1998-04-04', '2023-05-22', 2, 7),
(46, 'José', 'Peña', 'josep@email.com', '1982-12-19', '2023-05-25', 1, 8),
(47, 'Florencia', 'Acosta', 'florenciaa@email.com', '1995-07-26', '2023-05-28', 2, 9),
(48, 'Arturo', 'Méndez', 'arturom@email.com', '1981-03-03', '2023-06-01', 1, 10),
(49, 'Mariana', 'Vázquez', 'marianav@email.com', '1994-08-11', '2023-06-03', 2, 1),
(50, 'Esteban', 'Paredes', 'estebanp@email.com', '1988-01-20', '2023-06-05', 3, 2),
(51, 'Verónica', 'Cabrera', 'veronicac@email.com', '1997-09-05', '2023-06-07', 2, 3),
(52, 'Gabriel', 'Aguilar', 'gabriela@email.com', '1986-04-28', '2023-06-10', 3, 4),
(53, 'Silvia', 'Ramírez', 'silviar@email.com', '1990-10-14', '2023-06-12', 2, 5),
(54, 'Benjamín', 'Sánchez', 'benjamins@email.com', '1983-05-09', '2023-06-15', 1, 6),
(55, 'Constanza', 'Morales', 'constanzam@email.com', '1999-01-01', '2023-06-18', 2, 7),
(56, 'Marco', 'Romero', 'marcor@email.com', '1980-11-21', '2023-06-20', 1, 8),
(57, 'Josefina', 'Silva', 'josefinas@email.com', '1991-03-10', '2023-06-22', 2, 9),
(58, 'Sebastián', 'Fuentes', 'sebastianf@email.com', '1984-06-25', '2023-06-25', 1, 10),
(59, 'Emilia', 'Rojas', 'emiliar@email.com', '1996-08-08', '2023-06-28', 2, 1),
(60, 'Felipe', 'Valdés', 'felipev@email.com', '1987-02-12', '2023-07-01', 1, 2),
(61, 'Antonia', 'Parra', 'antoniap@email.com', '1993-05-17', '2023-07-03', 2, 3),
(62, 'Tomás', 'Salazar', 'tomass@email.com', '1981-10-29', '2023-07-05', 1, 4),
(63, 'Lorena', 'Miranda', 'lorenami@email.com', '1998-12-06', '2023-07-07', 2, 5),
(64, 'Martín', 'Campos', 'martinc@email.com', '1985-04-01', '2023-07-10', 1, 6),
(65, 'Agustina', 'Tapia', 'agustinat@email.com', '1992-09-13', '2023-07-12', 2, 7),
(66, 'Nicolás', 'Araya', 'nicolasa@email.com', '1980-07-02', '2023-07-15', 1, 8),
(67, 'Isidora', 'Herrera', 'isidorah@email.com', '1997-01-21', '2023-07-18', 3, 9),
(68, 'Joaquín', 'Núñez', 'joaquinn@email.com', '1989-11-15', '2023-07-20', 1, 10),
(69, 'Dominique', 'Contreras', 'dominiquec@email.com', '1994-06-03', '2023-07-22', 2, 1),
(70, 'Luciano', 'Rivas', 'lucianor@email.com', '1983-02-09', '2023-07-25', 1, 2),
(71, 'Daniela', 'Bravo', 'danielab@email.com', '1996-05-20', '2023-07-28', 2, 3),
(72, 'Álvaro', 'Lara', 'alvarol@email.com', '1986-10-08', '2023-08-01', 1, 4),
(73, 'Francisca', 'León', 'franciscal@email.com', '1990-12-23', '2023-08-03', 2, 5),
(74, 'Camilo', 'Castañeda', 'camiloc@email.com', '1981-08-04', '2023-08-05', 1, 6),
(75, 'Julieta', 'Cordero', 'julietac@email.com', '1999-03-16', '2023-08-07', 2, 7),
(76, 'Guillermo', 'Aguirre', 'guillermoa@email.com', '1980-09-18', '2023-08-10', 1, 8),
(77, 'Catalina', 'Sepúlveda', 'catalinas@email.com', '1991-01-07', '2023-08-12', 2, 9),
(78, 'Rodrigo', 'Benítez', 'rodrigob@email.com', '1984-04-26', '2023-08-15', 1, 10),
(79, 'Andrea', 'Vega', 'andreave@email.com', '1997-04-18', '2023-03-12', 2, 9),
(80, 'Fernando', 'Ruiz', 'fernandoru@email.com', '1985-12-03', '2023-03-15', 1, 10),
(81, 'Laura', 'Gómez', 'laurago@email.com', '1993-08-22', '2023-03-18', 2, 1),
(82, 'David', 'Martínez', 'davidma@email.com', '1991-06-30', '2023-03-20', 1, 2),
(83, 'Elena', 'Moreno', 'elenamo@email.com', '1996-02-14', '2023-03-22', 2, 3),
(84, 'Pablo', 'Jiménez', 'pabloji@email.com', '1989-10-01', '2023-03-25', 1, 4),
(85, 'Sofía', 'Hernández', 'sofiahe@email.com', '1994-07-07', '2023-03-28', 2, 5),
(86, 'Diego', 'González', 'diegogo@email.com', '1987-03-19', '2023-04-01', 1, 6),
(87, 'Gabriela', 'Rodríguez', 'gabrielaro@email.com', '1999-01-28', '2023-04-03', 2, 7),
(88, 'Daniel', 'Díaz', 'danieldi@email.com', '1986-05-12', '2023-04-05', 1, 8),
(89, 'Carolina', 'Santos', 'carolins@email.com', '1990-11-04', '2023-04-07', 2, 9),
(90, 'Andrés', 'Castro', 'andresca@email.com', '1995-09-16', '2023-04-10', 1, 10),
(91, 'Natalia', 'Ortega', 'natalio@email.com', '1992-04-23', '2023-04-12', 2, 1),
(92, 'Ricardo', 'Rubio', 'ricardoru@email.com', '1984-02-29', '2023-04-15', 1, 2),
(93, 'Marcela', 'Prieto', 'marcep@email.com', '1998-06-08', '2023-04-18', 2, 3),
(94, 'Jorge', 'Serrano', 'jorgesr@email.com', '1983-10-11', '2023-04-20', 1, 4),
(95, 'Camila', 'Vidal', 'camilavd@email.com', '1997-03-02', '2023-04-22', 2, 5),
(96, 'Cristian', 'Molina', 'cristianmo@email.com', '1982-07-27', '2023-04-25', 1, 6),
(97, 'Adriana', 'Navarro', 'adrianana@email.com', '1994-12-09', '2023-04-28', 2, 7),
(98, 'Javier', 'Delgado', 'javierde@email.com', '1981-01-13', '2023-05-01', 1, 8),
(99, 'Alejandra', 'Ibañez', 'alejandraib@email.com', '1991-05-01', '2023-05-03', 2, 9),
(100, 'Sergio', 'Guerrero', 'sergiogue@email.com', '1980-08-06', '2023-05-05', 1, 10),
(101, 'Diana', 'Ferrer', 'dianafe@email.com', '1996-10-17', '2023-05-07', 2, 1),
(102, 'Federico', 'Blanco', 'federicob@email.com', '1989-03-24', '2023-05-10', 1, 2),
(103, 'Paula', 'Gil', 'paula_gil@email.com', '1993-11-02', '2023-05-12', 2, 3),
(104, 'Gonzalo', 'Reyes', 'gonzalo_reyes@email.com', '1987-06-15', '2023-05-15', 1, 4),
(105, 'Victoria', 'Cruz', 'victoria_cruz@email.com', '1990-02-28', '2023-05-18', 2, 5),
(106, 'Manuel', 'Herrera', 'manuel_herrera@email.com', '1985-09-07', '2023-05-20', 1, 6),
(107, 'Jimena', 'Flores', 'jimena_flores@email.com', '1998-04-04', '2023-05-22', 2, 7),
(108, 'José', 'Peña', 'jose_pena@email.com', '1982-12-19', '2023-05-25', 1, 8),
(109, 'Florencia', 'Acosta', 'florencia_acosta@email.com', '1995-07-26', '2023-05-28', 2, 9),
(110, 'Arturo', 'Méndez', 'arturo_mendez@email.com', '1981-03-03', '2023-06-01', 1, 10),
(111, 'Mariana', 'Vázquez', 'mariana_vazquez@email.com', '1994-08-11', '2023-06-03', 2, 1),
(112, 'Esteban', 'Paredes', 'esteban_paredes@email.com', '1988-01-20', '2023-06-05', 1, 2),
(113, 'Verónica', 'Cabrera', 'veronica_cabrera@email.com', '1997-09-05', '2023-06-07', 2, 3),
(114, 'Gabriel', 'Aguilar', 'gabriel_aguilar@email.com', '1986-04-28', '2023-06-10', 1, 4),
(115, 'Silvia', 'Ramírez', 'silvia_ramirez@email.com', '1990-10-14', '2023-06-12', 2, 5),
(116, 'Benjamín', 'Sánchez', 'benjamin_sanchez@email.com', '1983-05-09', '2023-06-15', 1, 6),
(117, 'Constanza', 'Morales', 'constanza_morales@email.com', '1999-01-01', '2023-06-18', 2, 7),
(118, 'Marco', 'Romero', 'marco_romero@email.com', '1980-11-21', '2023-06-20', 1, 8),
(119, 'Josefina', 'Silva', 'josefina_silva@email.com', '1991-03-10', '2023-06-22', 2, 9),
(120, 'Sebastián', 'Fuentes', 'sebastian_fuentes@email.com', '1984-06-25', '2023-06-25', 1, 10),
(121, 'Emilia', 'Rojas', 'emilia_rojas@email.com', '1996-08-08', '2023-06-28', 2, 1),
(122, 'Felipe', 'Valdés', 'felipe_valdes@email.com', '1987-02-12', '2023-07-01', 1, 2),
(123, 'Antonia', 'Parra', 'antonia_parra@email.com', '1993-05-17', '2023-07-03', 2, 3),
(124, 'Tomás', 'Salazar', 'tomas_salazar@email.com', '1981-10-29', '2023-07-05', 1, 4),
(125, 'Lorena', 'Miranda', 'lorena_miranda@email.com', '1998-12-06', '2023-07-07', 2, 5),
(126, 'Martín', 'Campos', 'martin_campos@email.com', '1985-04-01', '2023-07-10', 1, 6),
(127, 'Agustina', 'Tapia', 'agustina_tapia@email.com', '1992-09-13', '2023-07-12', 2, 7),
(128, 'Nicolás', 'Araya', 'nicolas_araya@email.com', '1980-07-02', '2023-07-15', 1, 8),
(129, 'Isidora', 'Herrera', 'isidora_herrera@email.com', '1997-01-21', '2023-07-18', 2, 9),
(130, 'Joaquín', 'Núñez', 'joaquin_nunez@email.com', '1989-11-15', '2023-07-20', 1, 10),
(131, 'Dominique', 'Contreras', 'dominique_contreras@email.com', '1994-06-03', '2023-07-22', 2, 1),
(132, 'Luciano', 'Rivas', 'luciano_rivas@email.com', '1983-02-09', '2023-07-25', 1, 2),
(133, 'Daniela', 'Bravo', 'daniela_bravo@email.com', '1996-05-20', '2023-07-28', 2, 3),
(134, 'Álvaro', 'Lara', 'alvaro_lara@email.com', '1986-10-08', '2023-08-01', 1, 4),
(135, 'Francisca', 'León', 'francisca_leon@email.com', '1990-12-23', '2023-08-03', 2, 5),
(136, 'Camilo', 'Castañeda', 'camilo_castaneda@email.com', '1981-08-04', '2023-08-05', 1, 6),
(137, 'Julieta', 'Cordero', 'julieta_cordero@email.com', '1999-03-16', '2023-08-07', 2, 7),
(138, 'Guillermo', 'Aguirre', 'guillermo_aguirre@email.com', '1980-09-18', '2023-08-10', 1, 8),
(139, 'Catalina', 'Sepúlveda', 'catalina_sepulveda@email.com', '1991-01-07', '2023-08-12', 2, 9),
(140, 'Rodrigo', 'Benítez', 'rodrigo_benitez@email.com', '1984-04-26', '2023-08-15', 1, 10),
(141, 'Valentina', 'Soto', 'valentina_soto@email.com', '1995-02-02', '2023-08-18', 2, 1),
(142, 'Emilio', 'Miranda', 'emilio_miranda@email.com', '1982-11-29', '2023-08-20', 1, 2),
(143, 'Sofia', 'Díaz', 'sofia_diaz@email.com', '1997-07-07', '2023-08-22', 2, 3),
(144, 'Ignacio', 'Vargas', 'ignacio_vargas@email.com', '1988-03-14', '2023-08-25', 1, 4),
(145, 'Javiera', 'Tapia', 'javiera_tapia@email.com', '1990-09-19', '2023-08-28', 2, 5),
(146, 'Cristóbal', 'Flores', 'cristobal_flores@email.com', '1983-05-05', '2023-09-01', 1, 6),
(147, 'Josefa', 'Cáceres', 'josefa_caceres@email.com', '1992-01-23', '2023-09-03', 2, 7),
(148, 'Gonzalo', 'Reyes', 'gonzalo_reyes_2@email.com', '1987-06-15', '2023-09-05', 3, 8),
(149, 'Camila', 'Fernández', 'camila_fernandez@email.com', '1994-10-10', '2023-09-07', 3, 9),
(150, 'Esteban', 'Soto', 'esteban_soto@email.com', '1985-04-20', '2023-09-10', 3, 10);

INSERT INTO amistades (id_amistad, fecha_amistad, id_user_1, id_user_2) VALUES 
(1, '2024-01-12', 1, 2), (2, '2024-01-13', 3, 1), (3, '2024-01-16', 4, 5), (4, '2024-01-17', 6, 7), 
(5, '2024-01-18', 8, 9), (6, '2024-01-19', 10, 11), (7, '2024-01-20', 12, 13), (8, '2024-01-21', 14, 15), 
(9, '2024-01-22', 16, 17), (10, '2024-01-23', 18, 19), (11, '2024-01-24', 20, 21), (12, '2024-01-25', 22, 23), 
(13, '2024-01-26', 24, 25), (14, '2024-01-27', 26, 27), (15, '2024-01-28', 28, 29), (16, '2024-01-29', 30, 31), 
(17, '2024-01-30', 32, 33), (18, '2024-01-31', 34, 35), (19, '2024-02-01', 36, 37), (20, '2024-02-02', 38, 39), 
(21, '2024-02-03', 40, 41), (22, '2024-02-04', 42, 43), (23, '2024-02-05', 44, 45), (24, '2024-02-06', 46, 47), 
(25, '2024-02-07', 48, 49), (26, '2024-02-07', 4, 1), (27, '2024-02-07', 5, 9), (28, '2024-04-07', 4, 8), 
(29, '2024-02-07', 4, 2), (30, '2024-02-10', 4, 3);

INSERT INTO categorias (id_categoria, categoria) VALUES 
(1, 'Noticias y Medios'), (2, 'Deportes'), (3, 'Entretenimiento'), (4, 'Tecnología'), (5, 'Educación'), 
(6, 'Comunidad'), (7, 'Negocios Locales'), (8, 'Arte y Cultura'), (9, 'Salud y Bienestar'), (10, 'Viajes');

INSERT INTO tipo_publicacion (id_tipo, tipo_publicacion) VALUES (1, 'Texto'), (2, 'Foto'), (3, 'Video'), (4, 'Enlace');

-- PUBLICACIONES (105 registros)
INSERT INTO publicaciones (id_publicacion, id_user, id_tipo, contenido, fecha_publicacion, cantidad) VALUES 
(1, 1, 1, '¡Hola a todos! Mi primera publicación aquí.', '2024-01-11', 10),
(2, 2, 2, 'Hermoso atardecer de hoy. #Naturaleza', '2024-01-12', 3),
(3, 3, 1, 'Pensando en nuevas ideas para mi proyecto.', '2024-01-11', 6),
(4, 4, 3, 'Mi último video de viajes por el amazonas.', '2024-01-11', 20),
(5, 5, 1, '¡Feliz viernes a todos!', '2024-01-11', 10),
(6, 6, 2, 'Nueva foto de mi gato. ¡Adorable!', '2024-01-11', 15),
(7, 7, 1, 'Disfrutando de un buen libro.', '2024-01-20', 4),
(8, 8, 4, 'Artículo interesante sobre IA. [Enlace]', '2024-01-12', 14),
(9, 9, 1, 'Día productivo en la oficina.', '2024-01-12', 22),
(10, 10, 2, 'Vista desde la montaña. #Aventura', '2024-01-12', 10),
(11, 11, 1, 'Recordando viejos tiempos.', '2024-01-24', 0),
(12, 12, 3, 'Tutorial de programación básica.', '2024-01-12', 10),
(13, 13, 1, 'Preparándome para el fin de semana.', '2024-01-12', 10),
(14, 14, 1, 'Nuevas metas para el año.', '2024-01-30', 40),
(15, 15, 2, 'Selfie con mis amigos.', '2024-01-30', 20),
(16, 16, 1, 'Café mañanero.', '2024-01-30', 15),
(17, 17, 3, 'Fragmento de mi concierto.', '2024-01-30', 15),
(18, 18, 1, 'Lloviendo a cántaros.', '2024-01-31', 3),
(19, 19, 2, 'Mi almuerzo de hoy. #ComidaSaludable', '2024-02-01', 20),
(20, 20, 1, 'Paseo por el parque.', '2024-02-02', 5),
(21, 21, 4, 'Noticia de última hora. [Enlace]', '2024-02-03', 5),
(22, 22, 1, 'Cansado pero feliz.', '2024-02-04', 5),
(23, 23, 2, 'Mi nueva planta.', '2024-02-05', 5),
(24, 24, 1, 'Estudiando para el examen.', '2024-02-06', 10),
(25, 25, 3, 'Resumen de mi viaje.', '2024-02-07', 15),
(26, 26, 1, 'Gran día en la playa.', '2024-02-08', 0),
(27, 27, 2, 'Retrato. #Fotografía', '2024-02-09', 0),
(28, 28, 1, 'Meditando un rato.', '2024-02-10', 10),
(29, 29, 4, 'Consejos de productividad. [Enlace]', '2024-02-11', 10),
(30, 30, 1, 'Celebrando un logro.', '2024-02-12', 20),
(31, 31, 2, 'Decoración de mi hogar.', '2024-02-13', 30),
(32, 32, 1, 'Recién salido del gimnasio.', '2024-02-14', 5),
(33, 33, 3, 'Video de mis mascotas.', '2024-02-15', 0),
(34, 34, 1, 'Preparando la cena.', '2024-02-16', 0),
(35, 35, 2, 'Un paisaje espectacular.', '2024-02-17', 4),
(36, 36, 1, 'Recordando este momento.', '2024-02-18', 0),
(37, 37, 4, 'Tutorial de maquillaje. [Enlace]', '2024-02-19', 3),
(38, 38, 1, 'Qué buen concierto.', '2024-02-20', 2),
(39, 39, 2, 'Flores de mi jardín.', '2024-02-21', 1),
(40, 40, 1, 'Trabajando duro.', '2024-02-22', 10),
(41, 41, 3, 'Entrenamiento de hoy.', '2024-02-23', 15),
(42, 42, 1, 'Leyendo un buen libro.', '2024-02-24', 4),
(43, 43, 2, 'Arte callejero.', '2024-02-25', 6),
(44, 44, 1, 'Noche de películas.', '2024-02-26', 7),
(45, 45, 4, 'Receta saludable. [Enlace]', '2024-02-27', 8),
(46, 46, 1, 'Fin de semana perfecto.', '2024-02-28', 18),
(47, 47, 2, 'Mi nuevo look.', '2024-02-29', 3),
(48, 48, 1, 'Reflexionando sobre la vida.', '2024-03-01', 3),
(49, 49, 3, 'Unboxing de mi nuevo gadget.', '2024-03-02', 7),
(50, 50, 1, 'Desayuno delicioso.', '2024-03-03', 10),
(51, 51, 2, 'Amanecer en la ciudad.', '2024-03-04', 12),
(52, 52, 1, 'Planeando mi próxima aventura.', '2024-03-05', 4),
(53, 53, 4, 'Guía de viaje. [Enlace]', '2024-03-08', 2),
(54, 54, 1, 'Recordando este gran momento.', '2024-03-08', 3),
(55, 55, 2, 'Un selfie divertido.', '2024-03-08', 2),
(56, 56, 1, 'Trabajo en equipo.', '2024-03-09', 5),
(57, 57, 3, 'Resumen del evento.', '2024-03-10', 1),
(58, 58, 1, 'Nuevo día, nuevas oportunidades.', '2024-03-11', 0),
(59, 59, 2, 'Mis plantas creciendo.', '2024-03-12', 1),
(60, 60, 1, 'Disfrutando de la paz.', '2024-03-13', 1),
(61, 61, 4, 'Noticias de tecnología. [Enlace]', '2024-03-14', 10),
(62, 62, 1, '¡Qué semana!', '2024-03-15', 5),
(63, 63, 2, 'Puesta de sol increíble.', '2024-03-08', 5),
(64, 64, 1, 'Caminando por la naturaleza.', '2024-03-17', 5),
(65, 65, 3, 'Recopilación de mis mejores momentos.', '2024-03-08', 10),
(66, 66, 1, 'Agradecido por todo.', '2024-03-19', 5),
(67, 67, 2, 'Un día en la ciudad.', '2024-03-20', 5),
(68, 68, 1, 'Encuentros inesperados.', '2024-03-21', 0),
(69, 69, 4, 'Consejos de fitness. [Enlace]', '2024-03-22', 0),
(70, 70, 1, 'Noche de juegos.', '2024-03-23', 15),
(71, 71, 2, 'Mi arte favorito.', '2024-03-24', 10),
(72, 72, 1, 'Preparando un proyecto.', '2024-03-25', 5),
(73, 73, 3, 'Video musical favorito.', '2024-03-25', 5),
(74, 74, 1, 'Un buen café.', '2024-03-25', 5),
(75, 75, 2, 'Vista desde mi ventana.', '2024-03-28', 5),
(76, 76, 1, 'Celebrando la vida.', '2024-03-25', 2),
(77, 77, 4, 'Ideas para el hogar. [Enlace]', '2024-03-30', 15),
(78, 78, 1, 'Viernes de relax.', '2024-03-31', 15),
(79, 79, 2, 'Un bonito recuerdo.', '2024-04-01', 10),
(80, 80, 1, 'Nuevos desafíos.', '2024-04-02', 0),
(81, 81, 3, 'Momentos de la semana.', '2024-04-03', 20),
(82, 82, 1, 'Explorando nuevos lugares.', '2024-04-04', 15),
(83, 83, 2, 'Un día soleado.', '2024-04-05', 15),
(84, 84, 1, 'Reflexionando sobre el futuro.', '2024-04-06', 15),
(85, 85, 4, 'Tendencias de moda. [Enlace]', '2024-04-07', 0),
(86, 86, 1, '¡Qué aventura!', '2024-04-08', 0),
(87, 87, 2, 'Un momento de paz.', '2024-04-09', 20),
(88, 88, 1, 'Trabajo en progreso.', '2024-04-10', 10),
(89, 89, 3, 'Receta de cocina.', '2024-04-11', 0),
(90, 90, 1, 'Con amigos es mejor.', '2024-04-12', 10),
(91, 91, 2, 'Mi lugar favorito.', '2024-04-13', 4),
(92, 92, 1, 'Disfrutando cada día.', '2024-04-14', 2),
(93, 93, 4, 'Últimas noticias. [Enlace]', '2024-04-15', 6),
(94, 94, 1, 'Un gran concierto.', '2024-04-16', 15),
(95, 95, 2, 'Sesión de fotos.', '2024-04-17', 20),
(96, 96, 1, 'Inspirado hoy.', '2024-04-18', 25),
(97, 97, 3, 'Resumen de mi día.', '2024-04-19', 15),
(98, 98, 1, 'Aprender algo nuevo.', '2024-04-20', 0),
(99, 99, 2, 'Naturaleza pura.', '2024-04-21', 2),
(100, 100, 1, 'Momentos que atesoro.', '2024-04-22', 5),
(101, 101, 4, 'Consejos de marketing. [Enlace]', '2024-04-23', 10),
(102, 102, 1, 'Preparando el futuro.', '2024-04-24', 20),
(103, 103, 2, 'Un buen café y lectura.', '2024-04-25', 10),
(104, 104, 1, 'Caminando hacia mis sueños.', '2024-04-26', 40),
(105, 105, 3, 'Viaje en el tiempo.', '2024-04-27', 10);

INSERT INTO comentarios_publicaciones (id_comentario, id_user, id_publicacion, contenido, fecha_comentario) VALUES 
(1, 2, 1, '¡Excelente publicación, Juan!', '2024-01-11'), 
(2, 1, 2, '¡Qué atardecer tan bello!', '2024-01-12'), 
(3, 4, 3, '¡Mucho éxito con tu proyecto!', '2024-01-17'), 
(4, 5, 4, '¡Increíble video, me encantó!', '2024-01-18'), 
(5, 6, 5, '¡Feliz viernes para ti también, Lucía!', '2024-01-19'), 
(6, 7, 6, 'Tu gato es adorable.', '2024-01-20'), 
(7, 8, 7, 'Qué buen libro ¿Cuál es?', '2024-01-21'), 
(8, 9, 8, 'Muy interesante, gracias por compartir.', '2024-01-22'), 
(9, 10, 9, 'Felicidades por tu día productivo.', '2024-01-23'), 
(10, 11, 10, 'Impresionante vista.', '2024-01-24'), 
(11, 12, 11, 'Es bueno recordar lo bueno.', '2024-01-25'), 
(12, 13, 12, 'Muy útil, gracias.', '2024-01-26'), 
(13, 14, 13, '¡A disfrutar el fin de semana!', '2024-01-27'), 
(14, 15, 14, 'Buena vibra.', '2024-01-28'), 
(15, 16, 15, '¡Qué bien se la pasan!', '2024-01-29');

INSERT INTO conversaciones (id_conver, fecha_inicio) VALUES 
(1, '2024-01-10'), (2, '2024-01-11'), (3, '2024-01-15'), (4, '2024-01-16'), (5, '2024-01-17');

INSERT INTO fotos (id_foto, id_user, url, descripcion, fecha_subida) VALUES 
(1, 1, 'http://example.com/foto1.jpg', 'Mi primera foto de perfil.', '2024-01-10'), 
(2, 2, 'http://example.com/foto2.jpg', 'Foto de mis vacaciones en la playa.', '2024-01-11'), 
(3, 4, 'http://example.com/foto3.jpg', 'Paisaje de montaña.', '2024-01-15'), 
(4, 6, 'http://example.com/foto4.jpg', 'Mi mascota jugando.', '2024-01-16'), 
(5, 10, 'http://example.com/foto5.jpg', 'Foto de la ciudad de noche.', '2024-01-17');

INSERT INTO videos (id_video, id_user, url, descripcion, fecha_subida) VALUES 
(1, 1, 'http://example.com/video1.mp4', 'Mi primer video en la plataforma.', '2024-01-10'), 
(2, 4, 'http://example.com/video2.mp4', 'Tutorial de cocina fácil.', '2024-01-16'), 
(3, 12, 'http://example.com/video3.mp4', 'Rutina de ejercicios en casa.', '2024-01-18'), 
(4, 17, 'http://example.com/video4.mp4', 'Concierto en vivo.', '2024-01-20'), 
(5, 49, 'http://example.com/video5.mp4', 'Unboxing de un producto nuevo.', '2024-03-02');

INSERT INTO mensajes (id_mensaje, id_conver, id_user_emisor, id_user_receptor, contenido, fecha_envio) VALUES 
(1, 1, 1, 2, 'Hola Ana, ¿cómo estás?', '2024-01-10'), (2, 1, 2, 1, 'Hola Juan, muy bien, ¿y tú?', '2024-01-10'), 
(3, 2, 3, 1, 'Necesito ayuda con algo.', '2024-01-11'), (4, 2, 1, 3, 'Dime, ¿en qué te ayudo?', '2024-01-11'), 
(5, 3, 4, 5, '¿Nos vemos mañana?', '2024-01-15'), (6, 3, 5, 4, 'Claro, ¿a qué hora?', '2024-01-15'), 
(7, 4, 6, 7, '¿Qué tal el proyecto?', '2024-01-16'), (8, 4, 7, 6, 'Todo va bien, gracias.', '2024-01-16'), 
(9, 5, 8, 9, '¿Ya tienes los resultados?', '2024-01-17'), (10, 5, 9, 8, 'Casi, los envío pronto.', '2024-01-17');

INSERT INTO paginas (id_page, nombre, descripcion, id_categoria, id_user, fecha_creacion) VALUES 
(1, 'Noticias del Día', 'Tu fuente de noticias actualizada.', 1, 1, '2024-01-12'), 
(2, 'Deportes Extremos Bolivia', 'Todo sobre deportes de aventura.', 2, 3, '2024-01-18'), 
(3, 'Cinefilos Unidos', 'Reseñas y novedades del cine.', 3, 5, '2024-01-20'), 
(4, 'Tech Innovación', 'Noticias y análisis de tecnología.', 4, 7, '2024-02-01'), 
(5, 'Aprende y Crece', 'Contenido educativo para todos.', 5, 9, '2024-02-05');

INSERT INTO publicaciones_pagina (id_pub_page, id_page, contenido, id_tipo, fecha_publicacion) VALUES 
(1, 1, 'Últimas noticias: El clima en la región.', 1, '2024-01-13'), 
(2, 2, 'Resultados del partido de ayer. #Fútbol', 1, '2024-01-19'), 
(3, 3, 'Estreno de la película "El Viaje".', 1, '2024-01-21'), 
(4, 4, 'Nuevo smartphone en el mercado. ¡Conócelo!', 1, '2024-02-02'),
(5, 5, 'Consejos para mejorar tus habilidades de estudio.', 1, '2024-02-06');

INSERT INTO comentarios_publi_pages VALUES 
(1, 2, 1, 'Muy buena información.', '2024-01-14'), (2, 4, 2, '¡Vamos equipo!', '2024-01-20'), 
(3, 6, 3, 'Me gustó mucho la película.', '2024-01-22'), (4, 8, 4, 'Interesante gadget.', '2024-02-03'), 
(5, 10, 5, 'Buenos consejos, gracias.', '2024-02-07');

INSERT INTO tipo_reacciones (id_tipo_reaccion, tipo_reaccion) VALUES 
(1, 'Me gusta'), (2, 'Me encanta'), (3, 'Me divierte'), (4, 'Me asombra'), (5, 'Me entristece'), (6, 'Me enoja');

INSERT INTO reacciones (id_reaccion, id_user, id_publicacion, id_tipo_reaccion, fecha_reaccion) VALUES 
(1, 2, 1, 1, '2024-01-11'), (2, 1, 2, 2, '2024-01-12'), (3, 4, 3, 1, '2024-01-16'), (4, 5, 4, 2, '2024-01-17'), 
(5, 6, 5, 3, '2024-01-18'), (6, 7, 6, 1, '2024-01-19'), (7, 8, 7, 5, '2024-01-20'), (8, 9, 8, 4, '2024-01-21'), 
(9, 10, 9, 1, '2024-01-22'), (10, 11, 10, 2, '2024-01-23'), (11, 12, 11, 1, '2024-01-24'), (12, 13, 12, 2, '2024-01-25'), 
(13, 14, 13, 1, '2024-01-26'), (14, 15, 14, 2, '2024-01-27'), (15, 16, 15, 3, '2024-01-28'), (16, 17, 16, 1, '2024-01-29'), 
(17, 18, 17, 2, '2024-01-30'), (18, 19, 18, 5, '2024-01-31'), (19, 20, 19, 1, '2024-02-01'), (20, 21, 20, 2, '2024-02-02'), 
(21, 22, 21, 4, '2024-02-03'), (22, 23, 22, 1, '2024-02-04'), (23, 24, 23, 2, '2024-02-05'), (24, 25, 24, 1, '2024-02-06'), 
(25, 26, 25, 2, '2024-02-07');

INSERT INTO reacciones_publicaciones_page (id_reaccion, id_user, id_pub_page, id_tipo_reaccion, fecha_reaccion) VALUES 
(1, 1, 1, 1, '2024-01-13'), (2, 3, 2, 2, '2024-01-20'), (3, 5, 3, 1, '2024-01-22'), 
(4, 7, 4, 4, '2024-02-03'), (5, 9, 5, 1, '2024-02-07');

INSERT INTO seguidores_paginas (id_user_page, id_user, paginas_id_page, fecha_seguimiento) VALUES 
(1, 2, 1, '2024-01-12'), (2, 4, 1, '2024-01-13'), (3, 1, 2, '2024-01-19'), 
(4, 5, 2, '2024-01-20'), (5, 6, 3, '2024-01-21');

INSERT INTO sesiones (id_sesion, id_user, fecha_inicio, fecha_fin, ip) VALUES 
(1, 1, '2024-01-10', '2024-01-10', '192.168.1.100'), (2, 2, '2024-01-11', '2024-01-11', '192.168.1.101'), 
(3, 3, '2024-01-15', '2024-01-15', '192.168.1.102'), (4, 4, '2024-01-16', '2024-01-16', '192.168.1.103'), 
(5, 5, '2024-01-17', '2024-01-17', '192.168.1.104'), (6, 1, '2024-01-12', '2024-01-12', '192.168.1.100'), 
(7, 2, '2024-01-13', '2024-01-13', '192.168.1.101'), (8, 3, '2024-01-18', '2024-01-18', '192.168.1.102'), 
(9, 4, '2024-01-19', '2024-01-19', '192.168.1.103'), (10, 5, '2024-01-20', '2024-01-20', '192.168.1.104');

INSERT INTO tiempo (id_t, fecha, anio, mes, dia) VALUES 
(1, '2024-01-01', 2024, 1, 1), (2, '2024-01-11', 2024, 1, 11), (3, '2024-01-12', 2024, 1, 12), 
(4, '2024-01-13', 2024, 1, 13), (5, '2024-01-14', 2024, 1, 14), (6, '2024-01-15', 2024, 1, 15), 
(7, '2024-01-16', 2024, 1, 16), (8, '2024-01-17', 2024, 1, 17), (9, '2024-01-18', 2024, 1, 18), 
(10, '2024-01-19', 2024, 1, 19), (11, '2024-03-08', 2024, 3, 8), (12, '2024-01-30', 2024, 1, 30), 
(13, '2024-03-25', 2024, 3, 25), (14, '2024-01-20', 2024, 1, 20), (15, '2024-01-24', 2024, 1, 24), 
(16, '2024-01-31', 2024, 1, 31), (17, '2024-02-01', 2024, 2, 1), (18, '2024-02-02', 2024, 2, 2), 
(19, '2024-02-03', 2024, 2, 3), (20, '2024-02-04', 2024, 2, 4), (21, '2024-02-05', 2024, 2, 5), 
(22, '2024-02-06', 2024, 2, 6), (23, '2024-02-07', 2024, 2, 7), (24, '2024-02-08', 2024, 2, 8), 
(25, '2024-02-09', 2024, 2, 9), (26, '2024-02-10', 2024, 2, 10), (27, '2024-02-11', 2024, 2, 11), 
(28, '2024-02-12', 2024, 2, 12), (29, '2024-02-13', 2024, 2, 13), (30, '2024-02-14', 2024, 2, 14), 
(31, '2024-02-15', 2024, 2, 15), (32, '2024-02-16', 2024, 2, 16), (33, '2024-02-17', 2024, 2, 17), 
(34, '2024-02-18', 2024, 2, 18), (35, '2024-02-19', 2024, 2, 19), (36, '2024-02-20', 2024, 2, 20), 
(37, '2024-02-21', 2024, 2, 21), (38, '2024-02-22', 2024, 2, 22), (39, '2024-02-23', 2024, 2, 23), 
(40, '2024-02-24', 2024, 2, 24), (41, '2024-02-25', 2024, 2, 25), (42, '2024-02-26', 2024, 2, 26), 
(43, '2024-02-27', 2024, 2, 27), (44, '2024-02-28', 2024, 2, 28), (45, '2024-02-29', 2024, 2, 29), 
(46, '2024-03-01', 2024, 3, 1), (47, '2024-03-02', 2024, 3, 2), (48, '2024-03-03', 2024, 3, 3), 
(49, '2024-03-04', 2024, 3, 4), (50, '2024-03-05', 2024, 3, 5), (51, '2024-03-09', 2024, 3, 9), 
(52, '2024-03-10', 2024, 3, 10), (53, '2024-03-11', 2024, 3, 11), (54, '2024-03-12', 2024, 3, 12), 
(55, '2024-03-13', 2024, 3, 13), (56, '2024-03-14', 2024, 3, 14), (57, '2024-03-15', 2024, 3, 15), 
(58, '2024-03-17', 2024, 3, 17), (59, '2024-03-19', 2024, 3, 19), (60, '2024-03-20', 2024, 3, 20), 
(61, '2024-03-21', 2024, 3, 21), (62, '2024-03-22', 2024, 3, 22), (63, '2024-03-23', 2024, 3, 23), 
(64, '2024-03-24', 2024, 3, 24), (65, '2024-03-28', 2024, 3, 28), (66, '2024-03-30', 2024, 3, 30), 
(67, '2024-03-31', 2024, 3, 31), (68, '2024-04-01', 2024, 4, 1), (69, '2024-04-02', 2024, 4, 2), 
(70, '2024-04-03', 2024, 4, 3), (71, '2024-04-04', 2024, 4, 4), (72, '2024-04-05', 2024, 4, 5), 
(73, '2024-04-06', 2024, 4, 6), (74, '2024-04-07', 2024, 4, 7), (75, '2024-04-08', 2024, 4, 8), 
(76, '2024-04-09', 2024, 4, 9), (77, '2024-04-10', 2024, 4, 10), (78, '2024-04-11', 2024, 4, 11), 
(79, '2024-04-12', 2024, 4, 12), (80, '2024-04-13', 2024, 4, 13), (81, '2024-04-14', 2024, 4, 14), 
(82, '2024-04-15', 2024, 4, 15), (83, '2024-04-16', 2024, 4, 16), (84, '2024-04-17', 2024, 4, 17), 
(85, '2024-04-18', 2024, 4, 18), (86, '2024-04-19', 2024, 4, 19), (87, '2024-04-20', 2024, 4, 20), 
(88, '2024-04-21', 2024, 4, 21), (89, '2024-04-22', 2024, 4, 22), (90, '2024-04-23', 2024, 4, 23), 
(91, '2024-04-24', 2024, 4, 24), (92, '2024-04-25', 2024, 4, 25), (93, '2024-04-26', 2024, 4, 26), 
(94, '2024-04-27', 2024, 4, 27);