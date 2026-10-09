import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../network/api_client.dart';

enum FormStatus { idle, submitting, success, error }

class FormSubmitState<T> extends Equatable {
  final FormStatus status;
  final T? result;
  final String? error;
  const FormSubmitState({this.status = FormStatus.idle, this.result, this.error});

  FormSubmitState<T> copyWith({FormStatus? status, T? result, String? error}) =>
      FormSubmitState<T>(
          status: status ?? this.status, result: result ?? this.result, error: error);

  @override
  List<Object?> get props => [status, result, error];
}

// Wrapper generik utk create/update di form-sheet — dipakai ~10 halaman
// admin (produk/kategori/satuan/supplier/member/pengguna/voucher/...), sama
// seperti ListCubit generik menggantikan list-page per entity.
class FormSubmitCubit<T> extends Cubit<FormSubmitState<T>> {
  // Bukan `const FormSubmitState()`: const jadi FormSubmitState<Never> (lihat ListCubit).
  FormSubmitCubit() : super(FormSubmitState<T>());

  Future<T?> submit(Future<T> Function() action) async {
    emit(state.copyWith(status: FormStatus.submitting, error: null));
    try {
      final result = await action();
      emit(state.copyWith(status: FormStatus.success, result: result));
      return result;
    } catch (e) {
      final msg = e is String ? e : (isNetworkError(e) ? 'Tidak ada koneksi internet' : '$e');
      emit(state.copyWith(status: FormStatus.error, error: msg));
      return null;
    }
  }

  void reset() => emit(const FormSubmitState());
}
