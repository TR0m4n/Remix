// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract LocationObjets {
    // Structure représentant un objet à louer
    struct Objet {
        uint id;
        string nom;
        string description;
        uint tarifJournalier; // Tarif en wei par jour
        address payable proprietaire;
        bool disponible;
    }

    // Structure représentant une location
    struct Location {
        uint idObjet;
        address locataire;
        uint dateDebut;
        uint dateFin;
        bool active;
    }

    // Mapping des objets disponibles
    mapping(uint => Objet) public objets;
    uint public compteurObjets;

    // Mapping des locations en cours
    mapping(uint => Location) public locations;
    uint public compteurLocations;

    // Mapping pour stocker les objets associés à chaque utilisateur
    mapping(address => uint[]) public objetsParUtilisateur;

    // Événements pour suivre les actions
    event ObjetAjoute(uint id, string nom, address proprietaire);
    event ObjetLoue(uint idObjet, address locataire, uint dateDebut, uint dateFin);
    event LocationTerminee(uint idObjet, address locataire);

    // Ajouter un nouvel objet à louer
    function ajouterObjet(string memory _nom, string memory _description, uint _tarifJournalier) public {
        require(_tarifJournalier > 0, "Le tarif journalier doit etre superieur a zero.");
        compteurObjets++;
        objets[compteurObjets] = Objet(compteurObjets, _nom, _description, _tarifJournalier, payable(msg.sender), true);
        objetsParUtilisateur[msg.sender].push(compteurObjets);
        emit ObjetAjoute(compteurObjets, _nom, msg.sender);
    }

    // Louer un objet disponible
    function louerObjet(uint _idObjet, uint _jours) public payable {
        Objet storage objet = objets[_idObjet];
        require(objet.id != 0, "L'objet n'existe pas.");
        require(objet.disponible, "L'objet n'est pas disponible.");
        require(_jours > 0, "La duree de location doit etre superieure a zero.");
        uint montantTotal = objet.tarifJournalier * _jours;
        require(msg.value >= montantTotal, "Le montant envoye est insuffisant.");

        // Créer une nouvelle location
        compteurLocations++;
        locations[compteurLocations] = Location(_idObjet, msg.sender, block.timestamp, block.timestamp + (_jours * 1 days), true);
        objet.disponible = false;

        // Transférer les fonds au propriétaire
        objet.proprietaire.transfer(montantTotal);

        emit ObjetLoue(_idObjet, msg.sender, block.timestamp, block.timestamp + (_jours * 1 days));
    }

    // Terminer une location et rendre l'objet disponible
    function terminerLocation(uint _idLocation) public {
        Location storage location = locations[_idLocation];
        require(location.idObjet != 0, "La location n'existe pas.");
        require(location.locataire == msg.sender, "Vous n'etes pas le locataire de cette location.");
        require(location.active, "La location est deja terminee.");
        require(block.timestamp >= location.dateFin, "La periode de location n'est pas encore terminee.");

        // Rendre l'objet disponible à nouveau
        objets[location.idObjet].disponible = true;
        location.active = false;

        emit LocationTerminee(location.idObjet, msg.sender);
    }

    // Obtenir les objets d'un utilisateur
    function obtenirObjetsUtilisateur(address _utilisateur) public view returns (uint[] memory) {
        return objetsParUtilisateur[_utilisateur];
    }

    // Obtenir les détails d'un objet
    function obtenirObjet(uint _idObjet) public view returns (Objet memory) {
        require(objets[_idObjet].id != 0, "L'objet n'existe pas.");
        return objets[_idObjet];
    }

    // Obtenir les détails d'une location
    function obtenirLocation(uint _idLocation) public view returns (Location memory) {
        require(locations[_idLocation].idObjet != 0, "La location n'existe pas.");
        return locations[_idLocation];
    }
}
