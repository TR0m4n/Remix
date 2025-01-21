// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./snft-token.sol";

contract LocationObjets is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct Objet {
        uint id;
        string nom;
        uint tarifJournalier;
        address payable proprietaire;
        bool disponible;
    }

    struct Location {
        uint idObjet;
        address locataire;
        uint dateFin; // Utilisation de simulatedTime
    }

    uint private compteurObjets;
    mapping(uint => Objet) public objets;
    mapping(uint => Location) public locations;

    SNFTToken private token;

    uint public simulatedTime;

    // Événements
    event ObjetAjoute(uint id, string nom, address proprietaire);
    event ObjetLoue(uint idObjet, address locataire, uint dateFin);
    event LocationTerminee(uint idObjet, address locataire);

    constructor(address tokenAddress) {
        _grantRole(ADMIN_ROLE, msg.sender);
        token = SNFTToken(tokenAddress);
        simulatedTime = block.timestamp; // Initialisation avec le temps actuel
    }

    function ajouterObjet(string memory _nom, uint _tarifJournalier) public {
        require(_tarifJournalier > 0, "Le tarif journalier doit etre superieur a 0");
        compteurObjets++;
        objets[compteurObjets] = Objet(compteurObjets, _nom, _tarifJournalier, payable(msg.sender), true);
        emit ObjetAjoute(compteurObjets, _nom, msg.sender);
    }

    function louerObjet(uint _idObjet, uint _jours) public {
        Objet storage objet = objets[_idObjet];
        require(objet.disponible, "L'objet n'est pas disponible.");
        uint montant = objet.tarifJournalier * _jours;
        require(token.balanceOf(msg.sender) >= montant, "Solde insuffisant en tokens.");

        token.transferFrom(msg.sender, objet.proprietaire, montant);

        uint dateFin = simulatedTime + (_jours * 1 days); // Utilisation du temps simulé
        locations[_idObjet] = Location(_idObjet, msg.sender, dateFin);
        objet.disponible = false;

        emit ObjetLoue(_idObjet, msg.sender, dateFin);
    }

    function terminerLocation(uint _idObjet) public {
        require(locations[_idObjet].locataire != address(0), "Aucune location active pour cet objet.");
        require(locations[_idObjet].locataire == msg.sender, "Vous n'etes pas le locataire de cet objet.");
        require(simulatedTime >= locations[_idObjet].dateFin, "La location est encore en cours.");

        objets[_idObjet].disponible = true;
        delete locations[_idObjet];

        emit LocationTerminee(_idObjet, msg.sender);
    }
    function retirerTokens(address to, uint amount) public onlyRole(ADMIN_ROLE) {
        require(token.balanceOf(address(this)) >= amount, "Solde insuffisant dans le contrat.");
        token.transfer(to, amount);
    }

    function passerLeTemps(uint _jours) public onlyRole(ADMIN_ROLE) {
        require(_jours >= 1, "Vous devez specifier au moins un jour.");
        simulatedTime += _jours * 1 days;
    }

    function getSimulatedTime() public view returns (uint) {
        return simulatedTime;
    }
}