// SPDX-License-Identifier: MIT 
pragma solidity >=0.4.0;// <0.7.0;
//import "truffle/console.sol"; //Uitil para console.log pero no parece funcionar en VSCode

contract Contrato {

    //Variables de transacciones TODO: Agregar ID de transaccion
    struct Recarga{
        //idTransaccion; Pensar de que tipo ha de ser 
        uint16 consumo;//Energia consumida en KWh
        string dni;//DNI del usuario que uso la estacion
        uint fecha;//Fecha de la realizacion de la recarga
        string idEstacion;//Direccion de la estacion donde se hizo la recarga
        uint fechaLim;//Fecha de expiracion de la transaccion. Usado para penalizar en caso de retrasos
        int penalizaciones;//numero de penalizaciones aplicadas a la transaccion. Valor incial 0
        bool estado;//Estado de la recarga. true == pagado; false == pendiente de pagar. Valor inicial false
    }

    //Variables de contrato
    uint32 precioUnitario;//Precio por unidad de KWh consumido en transaciones
    address owner;//Direccion de la empresa dueña del contrato
    uint fechaExpiracion;//Fecha expriacion del contrato
    address[] asociado;//Empresas asociadas al mismo contrato con owner
    Recarga[] recargas;//Lista de recargas pagadas o a pagar a owner
    
    event TotalAPagar(uint128 coste, address empresa);
    event listaPendientes(Recarga[]lista, address empresa);

    function userInArray(string memory userId, string[] memory lista) private pure returns(bool) {
        for (uint i=0; i<lista.length;i++){
            //Como no existe comparacion nativa de string se convierten a 256 hashesh y secomparan
            if(keccak256(abi.encodePacked(lista[i])) == keccak256(abi.encodePacked(userId)))
            {
                return true;
            }
        }
        return false;
    }

    //Añadir recargas a la lista de transacciones TODO: VEr como generar nuevos id de transacciones al crear uno nuevo
    function nuevaRecarga(uint16 _consumo, string memory _dni, uint _fecha, string memory _estacion, uint _fechaLim) public{
        //Crearmos la nueva recarga a añadir al sistema
        Recarga memory recarga = Recarga({
            consumo: _consumo,
            dni: _dni,
            fecha: _fecha,
            idEstacion: _estacion,
            fechaLim: _fechaLim,
            penalizaciones: 0,
            estado:false
        });

        //Añadimos la recarga a la lisyta
        recargas.push(recarga);
    }


    //Muestra cuanto ha de pagar una compañia a otra dada su lista de usuarios
    function cantidadAPagar(string[] memory usuarios) public {
        uint64 consumoTotal=0;
        for (uint i =0;i<recargas.length;i++){

            if( userInArray(recargas[i].dni,usuarios) == true && recargas[i].estado == false){
                consumoTotal = consumoTotal + recargas[i].consumo; 
            }
        }
        //console.log("Total a pagar = ",consumoTotal*precioUnitario);//Salida por consola
        emit TotalAPagar(uint128(consumoTotal*precioUnitario),msg.sender);//Llamada a interfaz para mostrar el coste total a pagar calculado
    }

    //Altera el estado de recargas a true, en caso de que fecha sea menor al parametro fecha dado
    function cumplirRecargas(uint topFecha) public {
        for(uint i=0;i<recargas.length;i++){

            if(recargas[i].fecha<=topFecha){
            
                recargas[i].estado=true;
            
            }
        }
    }

    //Muestra lista de usuarios a pagar 
    //TODO: Ver como mejor implementarevl array temporal de pendientes. 
    function pagosPendientes(string[] memory usuarios) public {
        Recarga [] memory pendientes = new Recarga[] (100);
        uint j=0;
        for (uint i =0;i<recargas.length;i++){
            if( userInArray(recargas[i].dni,usuarios) == true && recargas[i].estado == false){
                //pendientes.push(recargas[i]); //por alguna razon no deja hacerlo       
                pendientes[j] = recargas[i];//implementacion sucio tratar de hallar mejor alternativa
                j++;
            }
        }
        //console.log("Total a pagar = ",consumoTotal*precioUnitario);//Salida por consola
        emit listaPendientes(pendientes,msg.sender);
    }


}