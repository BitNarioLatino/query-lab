/***Consultar Listado de Tablas***/
/** USAR : sp_spaceused 'NombreTabla'*/
/*SCRIPT : Listas todas las tablas de una BD*/
BEGIN
	USE AdventureWorks2019

	set nocount on
	DECLARE cursorTabla Cursor for
	SELECT 
	S.name +'.'+ O.name, S.name
	FROM sys.schemas S
	join sys.objects O on O.schema_id = S.schema_id
	where O.type = 'U'

	drop table if exists #Tablas
	create table #tablas(
	TablaNombre sysname,
	TablaRegistros nvarchar(50),
	TablaReservado nvarchar(20),
	TablaDatos nvarchar(20),
	TablaIndice nvarchar(20),
	TablaNoUsado nvarchar(20),
	TablaEsquema nvarchar(128))

	declare @Nombretablaconesquema sysname, @nombreesquema varchar(128)
	open cursortabla
	fetch cursortabla into @nombretablaconesquema,@nombreesquema
	while ( @@FETCH_STATUS = 0  )
	BEGIN
		print @Nombretablaconesquema+space(10)+@nombreesquema
		insert into #tablas
		(TablaNombre,TablaRegistros,TablaReservado,
		TablaDatos,TablaIndice,TablaNoUsado)
		exec sp_spaceused @nombretablaconesquema

		update #tablas
		set
		TablaEsquema = Left(@NombreTablaConEsquema,CHARINDEX('.',@NombreTablaConEsquema)-1)
		where TablaNombre = Right(@NombreTablaConEsquema,Len(@NombreTablaConEsquema)-CHARINDEX('.',@NombreTablaConEsquema))

		fetch cursorTabla into @Nombretablaconesquema,@nombreesquema
	END
	close cursortabla
	deallocate cursortabla

	select * from #tablas

	update
	#tablas
	set
	TablaReservado = left(tablareservado,len(tablareservado)-3),
	tabladatos = left(tabladatos,len(tabladatos)-3),
	tablaindice  = left(tablaindice,len(tablaindice)-3),
	tablanousado = left(tablanousado,len(tablanousado)-3)

	select * from #tablas
	order by convert(numeric(9,2),tablareservado) desc

END














exec sp_spaceused 'Person.Address'


CREATE TABLE productos (
  productoscodigo nchar(10),
  productosDescripcion nvarchar(200),
  productosPrecio numeric(9, 2),
  productosStock numeric(9, 2),
  productosFechaVencimiento date,
  productosOrigen nchar(1),
  productosFoto image,
  CONSTRAINT productopk PRIMARY KEY (productoscodigo)
)
GO

/***Uso de restricciones*/
/***consulta de Estrcutra de tabla***/
/**sp_help 'NombreTabla'**/
/* verificar que valores no cumplen con el check dbcc checkconstraints(Empleados)*/
/*	select * from sys.check_constraints
	select * from sys.foreign_keys
	select * from sys.default_constraints
	select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where constraint_type = 'unique'
	select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where constraint_type = 'primary key' */
/*ejemplos*/
BEGIN
	Create Database BDRestricciones
	Use BDRestricciones

	Create table Categorias
	(
	CategoriasCodigo nchar(4),
	CategoriasDescripcion nvarchar(50) not null,
	CategoriasEstado nchar(1)
	constraint CategoriasEstadoDF Default 'A',
	constraint CategoriasPK primary key (CategoriasCodigo),
	constraint CategoriasDescripcionUQ Unique (CategoriasDescripcion),
	constraint CategoriasEstadoCK
	check (CategoriasEstado = 'A' or CategoriasEstado = 'E')
	)

	sp_help Categorias

	create table Productos
		(
		ProductosCodigo nchar(10),
		ProductosDescripcion nvarchar(100) not null,
		ProductosPrecio Numeric(9,2)
		constraint ProductosPrecioDF default 0,
		ProductosStock Numeric(9,2)
		constraint ProductosStockDF default 0,
		CategoriasCodigo nchar(4),
		ProductosFechaRegistro Date,
		constraint ProductosFechaRegistroDF Default GetDate(),
		ProductosEstado nchar(1),
		constraint ProductosPK Primary key (ProductosCodigo),
		constraint ProductosCategoriasFK Foreign key (CategoriasCodigo)
		references Categorias(CategoriasCodigo),
		constraint ProductosDescripcionUQ Unique (ProductosDescripcion),
		constraint ProductosEstadoCK
		check (ProductosEstado = 'A' or ProductosEstado = 'E'),
		constraint ProductosPrecioCK check (ProductosPrecio >=0),
		constraint ProductosStockCK check (ProductosStock >=0),
	)

	Create table Clientes
	(
	ClientesCodigo nchar(15),
	ClientesRazonSocial nvarchar(100),
	ClientesDireccion nvarchar(200),
	ClientesEstado nchar(1),
	ClientesFechaRegistro Date
	)

	alter table Clientes alter column ClientesCodigo nchar(15) not null
	alter table CLientes add constraint ClientesPK primary key (Clientescodigo)
	Alter table Clientes add constraint ClientesRazonSocialUQ Unique(ClientesRazonSocial)
	alter table Clientes add constraint ClientesEstadoDF default 'A' for ClientesEstado
	alter table Clientes add constraint ClientesEStadoCK check(ClientesEStado = 'A' or ClientesEstado = 'E' )
	alter table Clientes add constraint ClientesFechaRegistroDF default getdate() for ClientesFechaRegistro
	alter table Clientes add constraint CLientesFechaRegistroCK check ( ClientesFechaRegistro < getdate())

	sp_help Clientes

	Create table Facturas
	(
	FacturasNumeroSerie nchar(5), 
	FacturasNumeroFactura nchar(7),
	FacturasFecha DateTime, 
	FacturasMontoSinIGV Numeric(9,2),
	FacturasPorcentajeDeIGV Numeric(8,5),
	ClientesCodigo nchar(15),
	FacturasMontoIGV As (FacturasMontoSinIGV * FacturasPorcentajeDeIGV),
	FacturasMontoTotal As (FacturasMontoSinIGV + FacturasMontoSinIGV * FacturasPorcentajeDeIGV )
	constraint FacturasPK primary key (FacturasNumeroSerie, FacturasNumeroFactura)
	)

	alter table facturas add constraint FacturasClientesFK foreign key (Clientescodigo)
	references Clientes(ClientesCodigo)

	create table Empleados
	(
	EmpleadosCodigo nchar(5),
	EmpleadosPaterno nvarchar(50),
	EmpleadosMaterno nvarchar(50),
	EmpleadosNombres nvarchar(50),
	EmpleadosFechaNacimiento Date,
	EmpleadosSueldo Numeric(9,2)
	constraint EmpleadosPK primary key (EmpleadosCodigo)
	)

	insert into Empleados values
	('AR996','Chavez','Pereda','Carlos','20000915',1800),
	('TR467','Terranova','Wong','José','19960224',3800),
	('BN789','Martinez','Alva','Cecilia','19831020',3850),
	('VT678','Sánchez','Llanos','Aracely','20000915',2980),
	('BH789','Nicolini','Mendoza','Amalia','19700723',1500)

	Alter table Empleados with nocheck
	add constraint EmpleadosSueldoCK Check (EmpleadosSueldo >= 2500)
	
	dbcc checkconstraints(Empleados)

	select * from Empleados where EmpleadosSueldo =1500 or EmpleadosSueldo = 1800

	select * from sys.check_constraints
	select * from sys.foreign_keys
	select * from sys.default_constraints
	select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where constraint_type = 'unique'
	select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where constraint_type = 'primary key' 

	alter table empleados nocheck constraint empleadossueldoCK
	insert into Empleados values
	('BY555','Palomino','Angeles','Susana','19770731',1780)

	alter table empleados check constraint empleadossueldoCK

	alter table clientes drop constraint CLientesFEchaREgistroDF

END














CREATE TABLE Niveles (
  NivelesCodigo nchar(10),
  NivelesDescricion nvarchar(200) NOT NULL,
  NivelesExplicacion nvarchar(100) CONSTRAINT nivelesExplicationDF DEFAULT '',
  nivelesfechacreacion date CONSTRAINT nivelesfechacreacionDF DEFAULT (GETDATE()),
  nivelesestado nchar(1) NOT NULL,
  NivelesEsdesistema nchar(1) NOT NULL CONSTRAINT NivelesesdesistemaDF DEFAULT 'N',
  CONSTRAINT nivelesPK PRIMARY KEY (nivelescodigo),
  CONSTRAINT nivelesestadoCK CHECK (NivelesEstado = 'A' OR NivelesEstado = 'E'),
  CONSTRAINT NivelesesdesistemaCK CHECK (nivelesesdesistema = 'S' OR nivelesesdesistema = 'S'),
  CONSTRAINT nivelesdescripcionUQ UNIQUE (NivelesDescricion)
)
GO

/* Relacionar la BD*/
/*Se hace con las restricciones Foreign key estableciendo la regla del negocio*/
begin
	create database restricciones
	use restricciones
	create table Categorias
	(
	CategoriasCodigo nchar(5),
	CategoriasDescripcion nvarchar(50) not null,
	CategoriasEstado nchar(1) constraint CategoriasEstadoDF default 'A',
	CategoriasFechaCreacion Date constraint CategoriasFechaCreacionDF default GetDate(),
	constraint CategoriasPK primary key (CategoriasCodigo),
	constraint CategoriasEstadoCK check (CategoriasEstado = 'A' or CategoriasEstado = 'E'),
	constraint CategoriasFechaCreacionCK check (CategoriasFechaCreacion > GetDate())
	)

	Create table Productos
	(
	ProductosCodigo nchar(8),
	ProductosDescripcion nvarchar(50) not null,
	CategoriasCodigo nchar(5),
	ProductosPrecio Numeric(9,2) 
	constraint ProductosPrecioDF default 0,
	ProductosStock Numeric(9,2) 
	constraint ProductosStockDF default 0,
	ProductosEstado nchar(1) 
	constraint ProductosEstadoDF default 'A',
	constraint ProductosPK primary key (ProductosCodigo),
	constraint ProductosEstadoCK check (ProductosEstado = 'A' or ProductosEstado = 'E'),
	constraint ProductosPrecioCK check (ProductosPrecio >=0),
	constraint ProductosStockCK check (ProductosStock >=0),
	constraint ProductosCategoriasFK Foreign key (CategoriasCodigo)
	references Categorias(CategoriasCodigo)
	)

	Create table Clientes
	(
	ClientesCodigo nchar(15),
	ClientesNombre nvarchar(100) not null,
	ClientesDireccion nvarchar(200),
	constraint ClientesPK Primary key (ClientesCodigo)
	)

	Create table Facturas
	(
	FacturasNumeroSerie nchar(5),
	FacturasNumeroFactura nchar(7),
	FacturasFecha DateTime,
	FacturasMontoSinIGV Numeric(9,2),
	FacturasPorcentajeDeIGV Numeric(8,5),
	ClientesCodigo nchar(15),
	FacturasMontoIGV As (FacturasMontoSinIGV * FacturasPorcentajeDeIGV),
	FacturasMontoTotal As (FacturasMontoSinIGV + FacturasMontoSinIGV * FacturasPorcentajeDeIGV )
	constraint FacturasPK primary key (FacturasNumeroSerie, FacturasNumeroFactura),
	constraint FacturasClienteFK Foreign key (ClientesCodigo)
	references Clientes(ClientesCodigo)
	)

	Create table DetalleFactura
	(
	FacturasNumeroSerie nchar(5),
	FacturasNumeroFactura nchar(7),
	ProductosCodigo nchar(8),
	ProductosDescripcion nvarchar(100),
	DetalleCantidadVendida Numeric(9,2),
	DetallePrecioVenta Numeric(9,2),
	DetalleOImporte As (DetalleCantidadVendida * DetallePrecioVenta)
	constraint DetalleFacturaPK Primary key
	(FacturasNumeroSerie,FacturasNumeroFactura,ProductosCodigo),
	constraint DetalleFacturaFacturasFK
	Foreign key (FacturasNumeroSerie,FacturasNumeroFactura)
	references Facturas (FacturasNumeroSerie,FacturasNumeroFactura),
	constraint DetalleFacturaProductosFK Foreign key (ProductosCodigo)
	references Productos (ProductosCodigo)
	)

	CReate table Empleados
	(
	EmpleadosCodigo nchar(4),
	EmpleadosPaterno nvarchar(50) not null,
	EmpleadosMaterno nvarchar(50) not null,
	EmpleadosNombres nvarchar(50) not null,
	EmpleadosFechaNacimiento Date,
	EmpleadosSexo nchar(1),
	EmpleadosCodigoJefe nchar(4),
	constraint EmpleadosPK primary key (EmpleadosCodigo),
	constraint EmpleadosEmpleadosFK foreign key (EmpleadosCodigoJefe)
	references Empleados(EmpleadosCodigo),
	constraint EmpleadosSexoCK check (EmpleadosSexo = 'F' or EmpleadosSexo = 'M')
	)


	/*AGREAGR RESTRCICIONES A TABLA EXISTENTES*/
	alter table Facturas Add EmpleadosCodigo nchar(4) not null
	Alter table Facturas Add constraint FacturasEmpleadosFK
	Foreign key (EmpleadosCodigo)
	references Empleados (EmpleadosCodigo)
end










CREATE TABLE grados (
  gradoscodigo nchar(10),
  gradosdescripcion nvarchar(200) NOT NULL,
  gradosfechacreacion date,
  gradosesdenivel nchar(10),
  gradosestado nchar(1) NOT NULL,
  CONSTRAINT gradosPK PRIMARY KEY (gradosCodigo),
  CONSTRAINT gradosnivelesFK FOREIGN KEY (gradosesdenivel) REFERENCES niveles (nivelescodigo)
)
GO