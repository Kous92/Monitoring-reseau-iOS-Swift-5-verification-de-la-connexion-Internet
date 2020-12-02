//
//  ViewController.swift
//  NetworkCheck
//
//  Created by Koussaïla Ben Mamar on 27/11/2020.
//

import UIKit
import Network

class ViewController: UIViewController {

    @IBOutlet weak var statutMonitoring: UILabel!
    @IBOutlet weak var voyantConnectivité: UIImageView!
    @IBOutlet weak var statutConnectivité: UILabel!
    @IBOutlet weak var typeConnexion: UILabel!
    @IBOutlet weak var bouton: UIButton!
    @IBOutlet var fondStatutRéseau: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        voyantConnectivité.isHidden = true
        statutConnectivité.isHidden = true
        typeConnexion.isHidden = true
        fondStatutRéseau.backgroundColor = UIColor(named: "Default")
        
        /*
        - Concernant les handlers de démarrage et d'arrêt du monitoring:
        -> Étant donné qu'il faut effectuer les traitements de détection réseau en tâche de fond et les changements sur l'interface dans
        le thread principal, il ne faut surtout pas laisser l'interface se figer et éviter la rétention en mémoire.
        -> Pour cela, on utilise [weak self] et [unowned self] dans la closure en paramètre d'entrée avant le "in".
           -> [weak self] si le contenu de self est optionnel ("nil" ou non)
           -> [unowned self] si le contenu de self n'est pas "nil". Si c'est "nil", l'appli iOS crashe !
        */
        NetworkStatus.shared.didStartMonitoringHandler = { [unowned self] in
            self.statutMonitoring.text = "Monitoring de la connectivité Internet: activé"
            self.voyantConnectivité.isHidden = false
            self.statutConnectivité.isHidden = false
            self.bouton.setTitle("Arrêter le monitoring", for: .normal)
        }
        
        NetworkStatus.shared.didStopMonitoringHandler = { [unowned self] in
            self.voyantConnectivité.isHidden = true
            self.statutConnectivité.isHidden = true
            self.typeConnexion.isHidden = true
            self.statutMonitoring.text = "Monitoring de la connectivité Internet: désactivé"
            fondStatutRéseau.backgroundColor = UIColor(named: "Default")
            self.bouton.setTitle("Démarrer le monitoring", for: .normal)
            // self.tableView.reloadData()
        }
        
        /*
         C'est ici dans la closure du handler de changement de statut réseau que les changements de l'état réseau en temps réel vont
         s'appliquer sur l'interface visuelle. Cela doit se faire dans le thread principal, donc de façon asynchrone avec DispatchQueue.main.async,
         cela permettant aussi d'éviter que l'interface se fige durant le traitement du monitoring.
         Il faut aussi en plus de l'opération en asynchrone, éviter la rétention en mémoire.
         -> Pour cela, on utilise [weak self] et [unowned self] dans la closure en paramètre d'entrée avant le "in".
            -> [weak self] si le contenu de self est optionnel ("nil" ou non)
            -> [unowned self] si le contenu de self n'est pas "nil". Si c'est "nil", l'appli iOS crashe !
        */
        NetworkStatus.shared.netStatusChangeHandler = {
            DispatchQueue.main.async { [unowned self] in
                print(NetworkStatus.shared.isConnected)
                if NetworkStatus.shared.isConnected {
                    self.voyantConnectivité.image = UIImage(named: "ok.png")
                    self.statutConnectivité.text = "Connecté"
                    self.typeConnexion.isHidden = false
                    fondStatutRéseau.backgroundColor = UIColor(named: "Connected")
                    
                    // On vérifie le type de connectivité
                    switch NetworkStatus.shared.connectionType {
                        case .wifi:
                            self.typeConnexion.text = "Type: Wi-Fi"
                            break
                        case .cellular:
                            self.typeConnexion.text = "Type: Données cellulaires"
                            break
                        case .ethernet:
                            self.typeConnexion.text = "Type: Ethernet"
                            break
                        case .loopback:
                            self.typeConnexion.text = "Type: Localhost"
                            break
                        default:
                            self.typeConnexion.text = "Type: Inconnu"
                            break
                    }
                } else {
                    voyantConnectivité.image = UIImage(named: "not_ok.png")
                    statutConnectivité.text = "Non connecté"
                    typeConnexion.isHidden = true
                    fondStatutRéseau.backgroundColor = UIColor(named: "Not connected")
                }
            }
        }
    }
    
    @IBAction func boutonMonitoring(_ sender: Any) {
        /* Si le monitoring n'est pas lancé, on le démarre. Lancé, on stoppe le monitoring.
        -> Avec les attributs d'instance et les handlers, les changements visuels s'appliqueront là-bas.
        */
        if !NetworkStatus.shared.isMonitoring {
            NetworkStatus.shared.startMonitoring()
        } else {
            NetworkStatus.shared.stopMonitoring()
        }
    }
}

