// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

//explication projet, en quoi la block chain permet de resoudre le problème, business, role;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./snft-token.sol";

contract LocationObjets is AccessControl {
// Définition des rôles
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
    uint dateFin;
    }
    uint compteurObjets;
    // Une mapping pour stocker les objets
    mapping(uint => Objet) public objets;

    mapping(uint => Location) public locations;

    event ObjetAjoute(uint id, string nom, address proprietaire);
    event ObjetLoue(uint idObjet, address locataire, uint dateFin);
    event LocationTerminee(uint idObjet, address locataire);


    SNFTToken private token;
   


    constructor(address tokenAddress) {
        _grantRole(ADMIN_ROLE, msg.sender);
        token = SNFTToken(tokenAddress);

    }

    function ajouterObjet(string memory _nom, uint _tarifJournalier) public {
    require(_tarifJournalier > 0);
    objets[++compteurObjets] = Objet(compteurObjets,_nom ,_tarifJournalier,payable(msg.sender),true);
    emit ObjetAjoute(compteurObjets, _nom,msg.sender);

    }
    function louerObjet(uint _idObjet,uint _jours) public {
    Objet storage objet=objets[_idObjet];
    require(objet.disponible,"L'objet n'est pas disponible.");
    uint montant= objet.tarifJournalier*_jours;
    require(token.balanceOf(msg.sender)>=montant, "Solde insuffisant en tokens.");

    token.transferFrom( msg.sender ,objets[_idObjet].proprietaire,montant);

    uint dateFin = block.timestamp + (_jours * 1 days);
    locations [_idObjet] = Location(_idObjet,msg.sender,dateFin );
    objet.disponible=false;
    emit ObjetLoue(_idObjet, msg.sender, dateFin); }

    function terminerLocation(uint _idObjet) public {
    require(locations[_idObjet].locataire == msg. sender);
    require(block.timestamp >= locations [_idObjet] .dateFin ,"La location est en cours.");

    objets[_idObjet].disponible = true;

    delete locations [ _idObjet];
    emit LocationTerminee(_idObjet, msg.sender); }

    // Fonction réservée aux administrateurs pour retirer des tokens
    function retirerTokens(address to,uint amount) public onlyRole(ADMIN_ROLE){
    require(token.balanceOf(address(this)) >=amount ,"Solde insuffisant dans le contrat.");
    token.transfer(to ,amount);
    }
}