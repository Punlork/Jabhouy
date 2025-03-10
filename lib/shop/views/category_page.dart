import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_app/l10n/l10n.dart';
import 'package:my_app/shop/shop.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({required this.category, required this.shop, super.key});
  final CategoryBloc category;
  final ShopBloc shop;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: category),
        BlocProvider.value(value: shop),
      ],
      child: const _CategoryPageContent(),
    );
  }
}

class _CategoryPageContent extends StatelessWidget {
  const _CategoryPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).category),
      ),
      body: BlocConsumer<CategoryBloc, CategoryState>(
        listener: (context, state) {
          switch (state) {
            case CategoryError():
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );

            default:
          }
        },
        builder: (context, state) {
          final items = state.asLoaded?.items ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAddCategoryButton(context);
              }
              final item = items[index - 1];
              return _buildCategoryTile(context, item);
            },
          );
        },
      ),
    );
  }

  Widget _buildAddCategoryButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        onPressed: () => _showCategoryDialog(context),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context).add),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, CategoryItemModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 12),
        title: Text(item.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showCategoryDialog(context, item: item),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(context, item),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, {CategoryItemModel? item}) {
    final isEdit = item != null;
    final controller = TextEditingController(text: item?.name ?? '');

    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CategoryBloc>(),
        child: AlertDialog(
          title: Text(
            isEdit ? AppLocalizations.of(context).editCategory : AppLocalizations.of(context).addCategory,
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).category, // Add to AppLocalizations
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  final bloc = context.read<CategoryBloc>();
                  final shopBloc = context.read<ShopBloc>();
                  if (isEdit) {
                    final body = item.copyWith(name: controller.text);
                    bloc.add(CategoryEditEvent(body: body));
                    if (shopBloc.state.asLoaded?.categoryFilter == item) {
                      context.read<ShopBloc>().add(ShopGetItemsEvent(categoryFilter: body));
                    }
                  } else {
                    bloc.add(
                      CategoryCreateEvent(
                        body: CategoryItemModel(
                          id: 0,
                          name: controller.text,
                          userId: '',
                        ),
                      ),
                    );
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(
                isEdit ? AppLocalizations.of(context).saveChanges : AppLocalizations.of(context).addItem,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, CategoryItemModel item) {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CategoryBloc>(),
        child: AlertDialog(
          title: Text(AppLocalizations.of(context).deleteCategory),
          content: Text(
            '${AppLocalizations.of(context).confirmDelete} ${item.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            TextButton(
              onPressed: () {
                context.read<CategoryBloc>().add(CategoryDeleteEvent(body: item));
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context).delete),
            ),
          ],
        ),
      ),
    );
  }
}
