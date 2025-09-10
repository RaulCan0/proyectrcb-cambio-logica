import 'package:flutter/material.dart';

class LentesMadurezPorRolTable extends StatelessWidget {
  final double scaleFactor;
  const LentesMadurezPorRolTable({super.key, this.scaleFactor = 1.0});

  DataCell wrapText(String text) => DataCell(
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 280 * scaleFactor),
          child: Text(text,
              softWrap: true,
              maxLines: 7,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13 * scaleFactor)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tabla de niveles de madurez por rol',
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 10.0 * scaleFactor,
            dataRowMinHeight: 05 * scaleFactor,
            dataRowMaxHeight: 160 * scaleFactor,
            headingRowHeight: 38 * scaleFactor,
            headingTextStyle: TextStyle(
              fontSize: 12 * scaleFactor,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF003056),
            ),
            dataTextStyle: TextStyle(
              fontSize: 12 * scaleFactor,
              color: Colors.black87,
            ),
            columns: const [
              DataColumn(label: Text('Lentes / Rol')),
              DataColumn(label: Text('Nivel 1\n0–20%', textAlign: TextAlign.center)),
              DataColumn(label: Text('Nivel 2\n21–40%', textAlign: TextAlign.center)),
              DataColumn(label: Text('Nivel 3\n41–60%', textAlign: TextAlign.center)),
              DataColumn(label: Text('Nivel 4\n61–80%', textAlign: TextAlign.center)),
              DataColumn(label: Text('Nivel 5\n81–100%', textAlign: TextAlign.center)),
            ],
            rows: [
              DataRow(cells: [
                const DataCell(Text('Ejecutivos')),
                wrapText('Los ejecutivos se centran principalmente en la lucha contra incendios y en gran parte están ausentes de los esfuerzos de mejora.'),
                wrapText('Los ejecutivos son conscientes de las iniciativas de otros para mejorar, pero en gran parte no están involucrados.'),
                wrapText('Los ejecutivos establecen la dirección para la mejora y respaldan los esfuerzos de los demás.'),
                wrapText('Los ejecutivos participan en los esfuerzos de mejora y respaldan el alineamiento de los principios de excelencia operacional con los sistemas.'),
                wrapText('Los ejecutivos se centran en garantizar que los principios de excelencia operativa se arraiguen profundamente en la cultura y se evalúen regularmente para mejorar.'),
              ]),
              DataRow(cells: [
                const DataCell(Text('Gerentes')),
                wrapText('Los gerentes están orientados a obtener resultados "a toda costa".'),
                wrapText('Los gerentes generalmente buscan especialistas para crear mejoras a través de la orientación del proyecto.'),
                wrapText('Los gerentes participan en el desarrollo de sistemas y ayudan a otros a usar herramientas de manera efectiva.'),
                wrapText('Los gerentes se enfocan en conductas de manejo a través del diseño de sistemas.'),
                wrapText('Los gerentes están "principalmente enfocados" en la mejora continua de los sistemas para impulsar un comportamiento más alineado con los principios de excelencia operativa.'),
              ]),
              DataRow(cells: [
                const DataCell(Text('Miembros del equipo')),
                wrapText('Los miembros del equipo se enfocan en hacer su trabajo y son tratados en gran medida como un gasto.'),
                wrapText('A veces se solicita a los asociados que participen en un equipo de mejora usualmente dirigido por alguien externo a su equipo de trabajo natural.'),
                wrapText('Están capacitados y participan en proyectos de mejora.'),
                wrapText('Están involucrados todos los días en el uso de herramientas para la mejora continua en sus propias áreas de responsabilidad.'),
                wrapText('Entienden los principios "el por qué" detrás de las herramientas y son líderes para mejorar sus propios sistemas y ayudar a otros.'),
              ]),
              DataRow(cells: [
                const DataCell(Text('Frecuencia')),
                wrapText('Infrecuente • Raro'),
                wrapText('Basado en eventos • Irregular'),
                wrapText('Frecuente • Común'),
                wrapText('Consistente • Predominante'),
                wrapText('Constante • Uniforme'),
              ]),
              DataRow(cells: [
                const DataCell(Text('Duración')),
                wrapText('Iniciado • Subdesarrollado'),
                wrapText('Experimental • Formativo'),
                wrapText('Repetible • Previsible'),
                wrapText('Establecido • Estable'),
                wrapText('Culturalmente Arraigado • Maduro'),
              ]),
              DataRow(cells: [
                const DataCell(Text('Intensidad')),
                wrapText('Apático • Indiferente'),
                wrapText('Aparente • Compromiso Individual'),
                wrapText('Moderado • Compromiso Local'),
                wrapText('Persistente • Amplio Compromiso'),
                wrapText('Tenaz • Compromiso Total'),
              ]),
              DataRow(cells: [
                const DataCell(Text('Alcance')),
                wrapText('Aislado • Punto de Solución'),
                wrapText('Silos • Flujo de Valor Interno'),
                wrapText('Predominantemente Operaciones • Flujo de Valor Funcional'),
                wrapText('Múltiples Procesos de Negocios • Flujo de Valor Integrado'),
                wrapText('En Toda la Empresa • Flujo de Valor Extendido'),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
