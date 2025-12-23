class Rendered {
  final String rendered;
  Rendered({required this.rendered});
  factory Rendered.fromJson(Map<String, dynamic> json) => Rendered(
        rendered: (json['rendered'] ?? '') as String,
      );
  Map<String, dynamic> toJson() => {'rendered': rendered};
}

class WpFeaturedMedia {
  final int id;
  final String sourceUrl;
  WpFeaturedMedia({required this.id, required this.sourceUrl});
  factory WpFeaturedMedia.fromJson(Map<String, dynamic> json) => WpFeaturedMedia(
        id: (json['id'] ?? 0) as int,
        sourceUrl: (json['source_url'] ?? '') as String,
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'source_url': sourceUrl,
      };
}

class WpEmbedded {
  final List<WpFeaturedMedia> featuredMedia;
  WpEmbedded({required this.featuredMedia});
  factory WpEmbedded.fromJson(Map<String, dynamic> json) {
    final List<dynamic> list = (json['wp:featuredmedia'] ?? []) as List<dynamic>;
    return WpEmbedded(
      featuredMedia: list
          .whereType<Map<String, dynamic>>()
          .map(WpFeaturedMedia.fromJson)
          .toList(),
    );
  }
  Map<String, dynamic> toJson() => {
        'wp:featuredmedia': featuredMedia.map((e) => e.toJson()).toList(),
      };
}

class WpPost {
  final int id;
  final String date;
  final String slug;
  final String link;
  final Rendered title;
  final Rendered? content;
  final Rendered excerpt;
  final int featuredMedia;
  final WpEmbedded? embedded;

  WpPost({
    required this.id,
    required this.date,
    required this.slug,
    required this.link,
    required this.title,
    required this.excerpt,
    this.content,
    required this.featuredMedia,
    this.embedded,
  });

  factory WpPost.fromJson(Map<String, dynamic> json) => WpPost(
        id: (json['id'] ?? 0) as int,
        date: (json['date'] ?? '') as String,
        slug: (json['slug'] ?? '') as String,
        link: (json['link'] ?? '') as String,
        title: Rendered.fromJson((json['title'] ?? {}) as Map<String, dynamic>),
        content: json['content'] != null
            ? Rendered.fromJson((json['content'] ?? {}) as Map<String, dynamic>)
            : null,
        excerpt: Rendered.fromJson((json['excerpt'] ?? {}) as Map<String, dynamic>),
        featuredMedia: (json['featured_media'] ?? 0) as int,
        embedded: json['_embedded'] != null
            ? WpEmbedded.fromJson((json['_embedded'] ?? {}) as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'slug': slug,
        'link': link,
        'title': title.toJson(),
        if (content != null) 'content': content!.toJson(),
        'excerpt': excerpt.toJson(),
        'featured_media': featuredMedia,
        if (embedded != null) '_embedded': embedded!.toJson(),
      };
}
