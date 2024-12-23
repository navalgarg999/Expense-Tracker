import 'package:expense_tracker/bar%20graph/bar_graph.dart';
import 'package:expense_tracker/components/my_list_tile.dart';
import 'package:expense_tracker/databse/expense_database.dart';
import 'package:expense_tracker/helper/helper_functions.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  Future<Map<String, double>>? _monthlyTotalsFuture;
  Future<double>? _calculateCurrentMonthTotal;
  @override
  void initState() {
    Provider.of<ExpenseDatabase>(context, listen: false).readExpenses();
    refreshData();
    super.initState();
  }

  void refreshData() {
    _monthlyTotalsFuture = Provider.of<ExpenseDatabase>(context, listen: false)
        .calculateMonthlyTotals();
    _calculateCurrentMonthTotal =
        Provider.of<ExpenseDatabase>(context, listen: false)
            .calculateCurrentMonthTotal();
  }

  void openNewExpenseBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: "Expense Name"),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(hintText: "Amount"),
            )
          ],
        ),
        actions: [
          _cancelButton(),
          _createnewExpensebutton(),
        ],
      ),
    );
  }

  void openeditbox(Expense expense) {
    String existingname = expense.name;
    String existingamount = expense.amount.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(hintText: existingname),
            ),
            TextField(
              controller: amountController,
              decoration: InputDecoration(hintText: existingamount),
            )
          ],
        ),
        actions: [
          _cancelButton(),
          _editExpenseButton(expense),
        ],
      ),
    );
  }

  void opendeletebox(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Expense"),
        actions: [
          _cancelButton(),
          _deleteExpenseButton(expense),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseDatabase>(
      builder: (context, value, child) {
        int startMonth = value.getStartMonth();
        int startYear = value.getStartYear();
        int currentMonth = DateTime.now().month;
        int currentYear = DateTime.now().year;

        int monthCount = calculateMonthCount(
            startYear, startMonth, currentYear, currentMonth);
        List<Expense> currentMonthExpenses = value.allExpense.where((expense) {
          return expense.date.year == currentYear &&
              expense.date.month == currentMonth;
        }).toList();
        return Scaffold(
          backgroundColor: Colors.grey.shade300,
          floatingActionButton: FloatingActionButton(
            onPressed: openNewExpenseBox,
            child: const Icon(Icons.add),
          ),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: FutureBuilder<double>(
              future: _calculateCurrentMonthTotal,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('\₹' + snapshot.data!.toStringAsFixed(2)),
                      Text(getCurrentMonthName()),
                    ],
                  );
                } else {
                  return Text("Loading....");
                }
              },
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 250,
                  child: FutureBuilder(
                    future: _monthlyTotalsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        Map<String, double> monthlyTotals = snapshot.data ?? {};

                        List<double> monthlySummary = List.generate(
                          monthCount,
                          (index) {
                            int year =
                                startYear + (startMonth + index - 1) ~/ 12;
                            int month = (startMonth + index - 1) % 12 + 1;

                            String yearMonthKey = '$year-$month';
                            return monthlyTotals[yearMonthKey] ?? 0.0;
                          },
                        );
                        return MyBarGraph(
                            monthlySummary: monthlySummary,
                            startMonth: startMonth);
                      } else {
                        return const Center(
                          child: Text("Loading..."),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: currentMonthExpenses.length,
                    itemBuilder: (context, index) {
                      int reversedIndex =
                          currentMonthExpenses.length - 1 - index;
                      Expense individualExpense =
                          currentMonthExpenses[reversedIndex];
                      return MyListTile(
                        title: individualExpense.name,
                        trailing: formatamount(individualExpense.amount),
                        onEditPressed: (context) =>
                            openeditbox(individualExpense),
                        onDeletePressed: (context) =>
                            opendeletebox(individualExpense),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cancelButton() {
    return MaterialButton(
      onPressed: () {
        Navigator.pop(context);

        nameController.clear();
        amountController.clear();
      },
      child: const Text('Cancel'),
    );
  }

  Widget _createnewExpensebutton() {
    return MaterialButton(
        onPressed: () async {
          if (nameController.text.isNotEmpty &&
              amountController.text.isNotEmpty) {
            Navigator.pop(context);

            Expense newExpense = Expense(
              name: nameController.text,
              amount: convertstringtodouble(amountController.text),
              date: DateTime.now(),
            );
            await context.read<ExpenseDatabase>().createNewExpense(newExpense);
            refreshData();

            nameController.clear();
            amountController.clear();
          }
        },
        child: const Text('Save'));
  }

  Widget _editExpenseButton(Expense expense) {
    return MaterialButton(
      onPressed: () async {
        if (nameController.text.isNotEmpty ||
            amountController.text.isNotEmpty) {
          Navigator.pop(context);
          Expense updatedExpense = Expense(
            name: nameController.text.isNotEmpty
                ? nameController.text
                : expense.name,
            amount: amountController.text.isNotEmpty
                ? convertstringtodouble(amountController.text)
                : expense.amount,
            date: DateTime.now(),
          );

          int existingId = expense.id;

          await context
              .read<ExpenseDatabase>()
              .updateExpense(existingId, updatedExpense);
        }
        refreshData();
      },
      child: const Text("Save"),
    );
  }

  Widget _deleteExpenseButton(Expense expense) {
    return MaterialButton(
      onPressed: () async {
        Navigator.pop(context);

        await context.read<ExpenseDatabase>().deleteExpense(expense.id);
        refreshData();
      },
      child: const Text("Delete"),
    );
  }
}
