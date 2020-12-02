# Monitoring réseau iOS (Swift 5): vérification de la connexion Internet

Dans toute application utilisant des services réseau (streaming, requêtes HTTP,...), le monitoring réseau est un cas commun qu'il faut mettre impérativement en place et s'assurer que lors de la vérification du réseau, que l'utilisateur soit bien connecté à Internet avant d'exécuter des appels réseau comme les requêtes HTTP. Également, il faut informer l'utilisateur s'il n'est pas connecté à Internet.

Pour cela, le framework Network du langage Swift va nous le permettre. 
```swift
import Network
```
**ATTENTION: iOS 12 ou ultérieur est nécessaire !**

Ici, voici donc une mini-application allant effectuer le monitoring réseau en temps réel dès qu'on l'active avec le bouton, pouvant être arrêté.

## Important à savoir
Pour des raisons d'optimalité, il faut éviter de créer plusieurs instances d'une classe (cela alourdit la mémoire et le processeur de threads) gérant le monitoring réseau, de même lorsqu'on fait des requêtes HTTP. Pour cela, il faut utiliser une instance partagée et utiliser la classe sous forme de singleton, un seul thread suffit donc pour cela.
```swift
class NetworkStatus 
{
    // Ici une seule instance (singleton) suffit pour le monitoring du réseau
    static let shared = NetworkStatus()

    // De ce fait, l'instance partagée va donc utiliser un constructeur privé
    private init() {

    }
}
```

Dans le ViewController, l'instance partagée (shared) pour effectuer les traitements s'effectuera comme ceci:
```swift
if !NetworkStatus.shared.isMonitoring 
{
    NetworkStatus.shared.startMonitoring()
}
else
{
    NetworkStatus.shared.stopMonitoring()
}
```

Également, tout traitement se fait de façon asynchrone:
 - Le monitoring réseau dans une tâche de fond (**background thread**)
 - Les changements dans l'interface réseau dans la tâche principale (**main thread**)

**L'utilisation de DispatchQueue est donc requise !**

Voici un cas concret pour appliquer des changements dans l'interface visuelle (ViewController)
```swift
NetworkStatus.shared.netStatusChangeHandler = {
    DispatchQueue.main.async { [unowned self] in
        if NetworkStatus.shared.isConnected 
        {
            self.statutConnectivité.text = "Connecté"
        }
        else
        {
            self.statutConnectivité.text = "Non connecté"
        }
    }
}
```

Et c'est aussi le cas pour le monitoring qui va surveiller en temps réel avec ceci:
```swift
func startMonitoring() 
{
    guard !isMonitoring else
    {
        return
    }

    monitor = NWPathMonitor()

    // Le monitoring de la connexion se fait dans un thread de fond (background thread)
    let queue = DispatchQueue(label: "NetworkMonitor")
    monitor?.start(queue: queue)
    print("Monitoring activé")

    /* Dans cette closure, c'est ici que le changement en temps réel s'applique.
    -> On va appeler le handler de changement de statut réseau, le traitement sera effectué dans le ViewController de façon asynchrone.
    -> On va récupérer le type de connectivité.
    */
    monitor?.pathUpdateHandler = { [unowned self] path in 
        self.netStatusChangeHandler?()
        getConnectionType(path)
    }

    isMonitoring = true
    didStartMonitoringHandler?()
}
```

N'oubliez pas aussi pour éviter la rétention en mémoire (donc des fuites) par les références faibles:
```swift
[weak self] // Self est optionnel, nil ou non
[unowned self] // Self n'est pas optionnel, si c'est nil, l'application crashe !
```

### Type de connectivité

Je vous laisse découvrir le reste dans le code source. Vous pourrez donc réutiliser le contenu dans vos propres applications.