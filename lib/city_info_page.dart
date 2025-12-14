import 'package:flutter/material.dart';
import 'package:meteo_app/data/models/city_info_model.dart';
import 'package:meteo_app/services/wikidata_service.dart';
import 'package:meteo_app/services/wikipedia_service.dart';  // ✨ NOUVEAU

/// Page d'informations détaillées sur une ville
/// 
///  AMÉLIORÉE avec les données Wikipedia :
/// - Historique de la ville
/// - Liste des monuments avec images et descriptions
class CityInfoPage extends StatefulWidget {
  final String initialCityName;

  const CityInfoPage({
    Key? key,
    required this.initialCityName,
  }) : super(key: key);

  @override
  State<CityInfoPage> createState() => _CityInfoPageState();
}

class _CityInfoPageState extends State<CityInfoPage> {
  final TextEditingController _searchController = TextEditingController();
  
  CityInfo? _currentCity;
  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCityInfo(widget.initialCityName);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Charge les informations d'une ville depuis Wikidata ET Wikipedia
  /// 
  /// AMÉLIORÉ : appelle les deux APIs
 Future<void> _loadCityInfo(String cityName) async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    // 1. Charger Wikidata
    final wikidataData = await WikidataService.fetchCityInfo(cityName);
    
    if (wikidataData == null) {
      setState(() {
        _errorMessage = 'Ville non trouvée';
        _isLoading = false;
      });
      return;
    }

    // Créer l'objet initial
    CityInfo city = CityInfo.fromJson(wikidataData);
    
    setState(() {
      _currentCity = city;  
      _isLoading = false;
    });

    // 2. Charger Wikipedia en arrière-plan
    final wikipediaData = await WikipediaService.fetchCityCompleteInfo(cityName);
    
    if (wikipediaData != null) {
      setState(() {
        _currentCity = city.copyWith(
          history: wikipediaData['history'],
          monuments: (wikipediaData['monuments'] as List?)
              ?.map((m) => Monument.fromJson(m))
              .toList() ?? [],
        );
      });
    }

  } catch (e) {
    setState(() {
      _errorMessage = 'Erreur : $e';
      _isLoading = false;
    });
  }
}
  /// Recherche une nouvelle ville
  void _searchCity() {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    _loadCityInfo(_searchController.text.trim()).then((_) {
      setState(() {
        _isSearching = false;
        _searchController.clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _buildCityContent(),
            ),
          ],
        ),
      ),
    );
  }

  /// Header avec bouton retour et barre de recherche
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                'Informations détaillées',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher une autre ville...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _searchCity,
                      color: Colors.blue,
                    ),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _searchCity(),
          ),
        ],
      ),
    );
  }

  /// État de chargement
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement des informations...'),
          SizedBox(height: 8),
          Text(
            'Récupération depuis Wikidata et Wikipedia',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// État d'erreur
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadCityInfo(widget.initialCityName),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Contenu principal avec toutes les infos de la ville
  Widget _buildCityContent() {
    if (_currentCity == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCityImage(),
          const SizedBox(height: 20),
          
          _buildDescriptionCard(),
          const SizedBox(height: 16),
          
          _buildInfoGrid(),
          const SizedBox(height: 16),
          
          // ✨ NOUVEAU : Section Historique
          if (_currentCity!.history != null) ...[
            _buildHistorySection(),
            const SizedBox(height: 16),
          ],
          
          if (_currentCity!.mayor != null) ...[
            _buildMayorCard(),
            const SizedBox(height: 16),
          ],
          
          if (_currentCity!.website != null) ...[
            _buildWebsiteCard(),
            const SizedBox(height: 16),
          ],
          
          // ✨ NOUVEAU : Section Monuments
          if (_currentCity!.monuments.isNotEmpty) ...[
            _buildMonumentsSection(),
            const SizedBox(height: 16),
          ],
          
          _buildSourceInfo(),
        ],
      ),
    );
  }

  /// Image de la ville avec le nom en overlay
  Widget _buildCityImage() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            _currentCity!.imageUrl != null
                ? Image.network(
                    _currentCity!.imageUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildImagePlaceholder(),
                  )
                : _buildImagePlaceholder(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentCity!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_currentCity!.country != null)
                    Text(
                      _currentCity!.country!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.blue[100],
      child: const Center(
        child: Icon(Icons.location_city, size: 80, color: Colors.blue),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'À propos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _currentCity!.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    final infos = [
      if (_currentCity!.population != null)
        _InfoItem(
          icon: Icons.people,
          label: 'Population',
          value: _currentCity!.population!,
          color: Colors.blue,
        ),
      if (_currentCity!.area != null)
        _InfoItem(
          icon: Icons.map,
          label: 'Superficie',
          value: _currentCity!.area!,
          color: Colors.green,
        ),
      if (_currentCity!.altitude != null)
        _InfoItem(
          icon: Icons.terrain,
          label: 'Altitude',
          value: _currentCity!.altitude!,
          color: Colors.purple,
        ),
      if (_currentCity!.founded != null)
        _InfoItem(
          icon: Icons.calendar_today,
          label: 'Fondée en',
          value: _currentCity!.founded!,
          color: Colors.orange,
        ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,  
        crossAxisSpacing: 9,    
        mainAxisSpacing: 9,      
      ),
      itemCount: infos.length,
      itemBuilder: (context, index) => _buildInfoCard(infos[index]),
    );
  }

  Widget _buildInfoCard(_InfoItem item) {
    return Container(
      padding: const EdgeInsets.all(12),  
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),  
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, 
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(  
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 20),  
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,  
                   color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),  
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 15,  
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✨ NOUVEAU : Section Historique
  Widget _buildHistorySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history_edu, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Historique',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currentCity!.history!,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMayorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.account_balance, color: Colors.indigo, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maire',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentCity!.mayor!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebsiteCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.language, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Site officiel',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentCity!.website!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, color: Colors.white),
        ],
      ),
    );
  }

  // ✨ NOUVEAU : Section Monuments
  Widget _buildMonumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_city, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Monuments et lieux célèbres',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Liste des monuments en cards horizontales
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _currentCity!.monuments.length,
          itemBuilder: (context, index) {
            final monument = _currentCity!.monuments[index];
            return _buildMonumentCard(monument);
          },
        ),
      ],
    );
  }

  /// Carte d'un monument individuel
  Widget _buildMonumentCard(Monument monument) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image du monument
          if (monument.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                monument.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            ),
          
          // Infos du monument
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monument.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                if (monument.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    monument.description!,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Informations sur la source des données
  Widget _buildSourceInfo() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              'Données fournies par Wikidata et Wikipedia',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_currentCity?.monuments.length ?? 0} monuments trouvés',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Classe helper pour les items d'information
class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}