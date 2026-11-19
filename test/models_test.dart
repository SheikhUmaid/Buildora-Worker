import 'package:buildora_worker/core/format.dart';
import 'package:buildora_worker/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('budget formatting uses Indian units', () {
    expect(Fmt.budget(12000000), '₹1.20 Cr');
    expect(Fmt.budget(4500000), '₹45.0 L');
    expect(Fmt.budget(null), 'Hidden');
  });

  test('initials', () {
    expect(Fmt.initials('Rakesh Nair'), 'RN');
    expect(Fmt.initials('abhinav'), 'A');
  });

  test('project parses populated engineer and hidden budget', () {
    final p = Project.fromJson({
      'id': 'p1',
      'name': 'Skyline Villa',
      'status': 'in_progress',
      'progress': 62,
      'budget': null,
      'engineer': {'id': 'e1', 'name': 'Rakesh Nair', 'role': 'engineer', 'phone': '+91 98450 12345'},
      'clients': [
        {'id': 'c1', 'name': 'Abhinav Gupta'},
      ],
      'openRequests': 2,
    });
    expect(p.budget, isNull);
    expect(p.engineer?.name, 'Rakesh Nair');
    expect(p.engineerId, 'e1');
    expect(p.primaryClient?.name, 'Abhinav Gupta');
    expect(p.openRequests, 2);
  });

  test('update summary', () {
    final u = SiteUpdate.fromJson({
      'id': 'u1',
      'project': 'p1',
      'date': '2026-10-18T00:00:00.000Z',
      'photos': ['/uploads/a.jpg', '/uploads/b.jpg'],
      'totalLaborers': 18,
      'author': {'kind': 'laborer', 'id': 'l1', 'name': 'Manoj Kumar'},
    });
    expect(u.summary, '2 photos · 18 laborers');
    expect(u.byLaborer, isTrue);
    expect(u.projectId, 'p1');
  });

  test('request parses unpopulated update reference', () {
    final r = ClientRequest.fromJson({'id': 'r1', 'type': 'question', 'status': 'new', 'update': 'u9', 'project': 'p1'});
    expect(r.updateId, 'u9');
    expect(r.projectId, 'p1');
    expect(r.isOpen, isTrue);
  });
}
