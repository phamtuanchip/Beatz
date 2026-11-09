import 'package:beatz/blocs/home_page_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HomePageBloc emits page indexes in order', () {
    final bloc = HomePageBloc();
    bloc.pageIndex.add(1);
    bloc.pageIndex.add(3);
    bloc.pageIndex.add(0);
    expect(bloc.pageIndexStream, emitsInOrder([1, 3, 0]));
  });
}
