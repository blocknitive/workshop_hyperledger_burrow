pragma solidity ^0.4.18;

// @author miguel.martinez@blocknitive.com
contract HackathonBlocknitive {
    
    string nombreRegistro;

    constructor() {
        nombreRegistro = "Hackathon de Blocknitive";
    }

    function getNombreRegistro() constant public returns (string) {
        return nombreRegistro;
    }


    function setNombreRegistro(string _nombre) public {
        nombreRegistro = _nombre;
    }

}
