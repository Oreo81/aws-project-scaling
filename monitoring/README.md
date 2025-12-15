Les instances doivent être taggées PrometheusScrape=true via l’ASG tags (voir Terraform snippet ci-dessous) afin que Prometheus les détecte.

```
resource "aws_autoscaling_group" "example" {
  name                      = "example-asg"
  # ... launch_configuration / launch_template etc ...
  min_size  = 1
  max_size  = 3
  desired_capacity = 1
  # autres paramètres (subnets, vpc_zone_identifier, target_group_arns...) 

  tag {
    key                 = "PrometheusScrape"
    value               = "true"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "app-instance"
    propagate_at_launch = true
  }
}

```

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeTags",
        "ec2:DescribeRegions"
      ],
      "Resource": "*"
    }
  ]
}

```

Attache cette policy au role EC2 de l’instance qui exécute Prometheus.

---

8) Exemples de commandes utiles

Démarrer monitoring :

cd monitoring
./install_monitoring.sh


Voir logs Prometheus :

docker logs -f prometheus


Vérifier cibles dans Prometheus UI : http://<PROM_HOST>:9090/targets

Accéder Grafana : http://<PROM_HOST>:3000 (admin/admin par défaut — change le mot de passe au premier login)

Points importants / sécurité / paramètres à ajuster

Rôle IAM : préférable à l’injection de clés. Prometheus doit pouvoir DescribeInstances.

Région : change region: "eu-west-1" dans prometheus.yml pour ta région (ex : eu-west-3 si Paris).

Ports & Security Groups :

node_exporter écoute sur 9100 (ouverte uniquement pour le monitoring SG depuis la machine Prometheus ou VPC interne).

Prometheus (9090) et Grafana (3000) peuvent être restreints (accès via bastion ou VPN).

Tagging : l’ASG doit propager le tag PrometheusScrape=true.

Haute disponibilité : cette configuration est simple (1 instance prometheus). Pour un projet plus avancé, prévoir HA, stockage durable, backups et métriques à haute-résolution.

Versions : j’ai utilisé images latest ; verrouillez les versions en prod.

Résumé rapide d’action (checklist)

Créer instance EC2 monitoring avec rôle IAM autorisant ec2:DescribeInstances.

Transférer l’arborescence monitoring/ sur cette instance.

chmod +x install_monitoring.sh puis ./install_monitoring.sh.

Configurer l’ASG/Launch Template pour installer node_exporter (user-data) et tagger PrometheusScrape=true.