import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/domain/cv/cv_template_registry.dart';

void main() {
  test('registry exposes the three Nexora templates', () {
    expect(CvTemplateRegistry.all.length, 3);
    expect(CvTemplateRegistry.all.map((t) => t.id).toSet(),
        {'nexoraMinimal', 'nexoraModern', 'nexoraCompact'});
    expect(CvTemplateRegistry.isValid('nexoraMinimal'), isTrue);
    expect(CvTemplateRegistry.isValid('nope'), isFalse);
  });

  test('byId falls back to the default template for unknown ids', () {
    final fallback = CvTemplateRegistry.byId('does-not-exist');
    expect(fallback.id, CvTemplateRegistry.defaultTemplateId);
  });
}
