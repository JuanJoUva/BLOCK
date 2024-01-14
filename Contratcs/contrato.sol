// SPDX-License-Identifier: MIT 
pragma solidity >=0.4.0;// <0.7.0;
//import "truffle/console.sol"; //Uitil para console.log pero no parece funcionar en VSCode


contract Contrato {

    //Variable de transacciones
    struct Recarga{
        //Idenntificadores de transaccion
        address dni;//DNI del usuario que uso la estacion
        uint fecha;//Fecha de la realizacion de la recarga
        uint16 consumo;//Energia consumida en Wh
        uint idEstacion;//Direccion de la estacion donde se hizo la recarga
        uint costeRecarga;//Coste de la recarga en centimos/wh

    }

    //Variables de contrato
    uint32 precioUnitario;//Precio por unidad de Wh consumido en transaciones
    uint fechaExpiracion;//Fecha expriacion del contrato
    
    mapping(address => uint) private saldoProveedor;
    mapping(address => uint) private saldoUsuario;
    mapping(uint => address) private estacionProveedor;
    mapping(address => address) private usuarioProveedor;
    mapping(address => Recarga[]) private recargasPendientes;

    event TotalAPagar(uint128 coste, address proveedor);
    event listaPendientes(Recarga[]lista, address proveedor);

    constructor(uint fechaFin, uint32 coste){
        fechaExpiracion = fechaFin;
        precioUnitario = coste;
        
        //Empresa 1 (JJ)
        address proveedor1 = 0xf2484fe847B34ad6A677fFd603221f70781FDC48;
        saldoProveedor[proveedor1] = 10000000;
        estacionProveedor[1] = proveedor1;
        estacionProveedor[2] = proveedor1;
        estacionProveedor[3] = proveedor1;

        //Empresa 2 (David)
        address proveedor2 = 0xFCD633FE4F4bE41d49aAf665Ae75D3a24e1B210b;
        saldoProveedor[proveedor2] = 10000000;
        estacionProveedor[5] = proveedor2;
        estacionProveedor[6] = proveedor2;
        estacionProveedor[7] = proveedor2;

        //Usuario 1 (JJ) 
        address usuario1 = 0x7eE02Ce510DcFe584BD197453125D28C0b675D1A;
        saldoUsuario[usuario1] = 20000;
        usuarioProveedor[usuario1] = proveedor1;
        
        //Usuario 2 (David) 
        address usuario2 = 0x0B782436FC56Eb8d2b6c7aFE81e2D510670F7f94;
        saldoUsuario[usuario2] = 20000;
        usuarioProveedor[usuario2] = proveedor2;
    }


    //Añadir recargas a la lista de transacciones
    //LLamda por usuarios de estaciones de recargas
    function registrarRecarga(uint16 _consumo, uint _fecha, uint _estacion) public{
        
        //Verificamos que el usuario puede pagar la recarga
        uint coste = _consumo * precioUnitario;
        require(saldoUsuario[msg.sender] >= coste, "No tienes saldo suficiente para hacer la recarga");
        //Crearmos la nueva recarga a añadir al sistema
        Recarga memory nuevaRecarga = Recarga({
            consumo: _consumo,
            dni: msg.sender,
            fecha: _fecha,
            idEstacion: _estacion,
            costeRecarga: coste
        });

        //Eliminamos saldo al usuario
        saldoUsuario[msg.sender] -= coste;
        
        //Añadimos saldo al prveedor
        address proveedorUsr = usuarioProveedor[msg.sender];
        saldoProveedor[proveedorUsr] += coste;

        //Añadimos la recarga a pendientes a pagar
        address proveedorUsuario = usuarioProveedor[msg.sender];
        recargasPendientes[proveedorUsuario].push(nuevaRecarga);

    }

    //Extrae y muestra la lista de pagos pendientes que tiene una proveedores
    //Funcion ejecutada por proveedores
    function pagosPendientes() public {

        Recarga[] memory pendientes =recargasPendientes[msg.sender]; 
        emit listaPendientes(pendientes,msg.sender);
    }

    //Funcion que salda las deudas, de la empresa que llama a este metodo
    function saldarDeudas() public{
        //Extraemos la lista de transacciones pendientes
        Recarga[] memory pendientes=recargasPendientes[msg.sender]; 
        require(pendientes.length >0 , "No tienes deudas registradas en el sistema");

        //Leer la lista, calcular el coste total a pagar Total, y saldar la deuda de las recargas, siempre que pueda
        for (uint i =0;i<pendientes.length;i++){
            uint coste = pendientes[i].consumo * precioUnitario;
            require(saldoProveedor[msg.sender] >= coste, "No tienes saldo suficiente para pagar tus deudas");
            saldoProveedor[msg.sender] -= coste;

            //Hallamos a quien tiene que pagarle el Proveedor que ha hecho la peticion
            address proveedorAPagar = estacionProveedor[pendientes[i].idEstacion];
            saldoProveedor[proveedorAPagar] += coste; 
        }

        //vaciamos lista de pendientes
        delete recargasPendientes[msg.sender];
    }


}