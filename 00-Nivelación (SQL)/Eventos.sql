/* 
Este modelo se conecta de la siguiente manera:
usuario → compra → ticket → evento 
*/

CREATE TABLE evento (
  id integer PRIMARY KEY,
  nombre varchar,
  fecha date,
  capacidad integer,
  modalidad varchar
);

CREATE TABLE ticket (
  id integer PRIMARY KEY,
  evento_id integer NOT NULL REFERENCES evento,
  categoria varchar NOT NULL,
  precio decimal,
  UNIQUE(evento_id,categoria)
);

CREATE TABLE usuario (
  id integer PRIMARY KEY,
  nombre varchar,
  email varchar
);

CREATE TABLE compra (
  user_id integer NOT NULL REFERENCES usuario,
  ticket_id integer NOT NULL REFERENCES ticket,
  fecha date NOT NULL,
  forma_pago varchar,
  PRIMARY KEY(user_id, ticket_id, fecha)
);

INSERT INTO evento(id,nombre,fecha,capacidad,modalidad) VALUES
(25,'Taller de escritura I','2025/05/02',20,'virtual'),
(44,'Karaoke entre amigos','2025/06/01',60,'presencial'),
(82,'Recital alumnos clases de piano','2025/05/09',200,'presencial'),
(29,'Taller de escritura II','2025/08/08',100,'virtual'),
(34,'Seminario/Taller de meditación','2025/05/23',30,'presencial'),
(38,'Curso html básico (4 hs)','2025/05/14',20,'virtual');

INSERT INTO ticket(id,evento_id,categoria,precio) VALUES
(1900,25,'única',8000),
(2300,44,'VIP',20000),
(2350,44,'estándar',10000),
(1200,82,'alumno',2000),
(1250,82,'familiar',5000),
(1290,29,'única',8000),
(2440,34,'alumno',9000),
(1800,38,'única',25000);

INSERT INTO usuario(id,nombre,email) VALUES
(100,'Luna','luna@dominio.com.ar'),
(110,'Nahuel','nahu2006@gmail.com'),
(120,'Martina','martu@midom.edu.ar'),
(130,'Alicia','alicita@yahoo.com.ar'),
(140,'Francisco','franporto@gmail.com'),
(150,'Ulises','ulises@dominio.com.ar'),
(160,'Uma','uma15@otrodom.uy'),
(170, 'Carlos','car1111@otrodom.uy');

INSERT INTO compra(user_id,ticket_id,fecha,forma_pago) VALUES
(100,2300,'2025/04/03','MP'),
(110,2300,'2025/04/22','Visa'),
(160,2300,'2025/03/26','MP'),
(140,2350,'2025/04/08','MP'),
(150,2350,'2025/04/02','Transf.'),
(120,1900,'2025/04/05','MP'),
(130,1900,'2025/04/12','MP'),
(130,2440,'2025/04/09','Transf.'),
(100,1200,'2025/03/09','MP'),
(150,1200,'2025/04/01','MP'),
(160,1250,'2025/04/09','MP'),
(120,1250,'2025/04/12','MP'),
(110,1200,'2025/03/19','MP')





