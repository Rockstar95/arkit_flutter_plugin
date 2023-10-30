import 'package:arkit_plugin/src/arkit_node.dart';
import 'package:arkit_plugin/src/light/arkit_light.dart';
import 'package:arkit_plugin/src/physics/arkit_physics_body.dart';
import 'package:vector_math/vector_math_64.dart';

///  Node that references an external serialized node graph.
class ARKitReferenceNode extends ARKitNode {
  ARKitReferenceNode({
    this.url = "",
    this.remoteUrl = "",
    this.remoteObjectFileName = "",
    ARKitPhysicsBody? physicsBody,
    ARKitLight? light,
    Vector3? position,
    Vector3? scale,
    Vector3? eulerAngles,
    String? name,
    int renderingOrder = ARKitNode.defaultRenderingOrderValue,
    bool isHidden = ARKitNode.defaultIsHiddenValue,
  }) : super(
          physicsBody: physicsBody,
          light: light,
          position: position,
          scale: scale,
          eulerAngles: eulerAngles,
          name: name,
          renderingOrder: renderingOrder,
          isHidden: isHidden,
        );

  /// URL location of the Node
  /// Defaults to path from Main Bundle
  /// If path from main bundle fails, will search as full file path
  final String url;

  /// URL location of the Node
  /// Defaults to empty
  /// It is url of remote object
  final String remoteUrl;

  /// File Name of the object exist in Remote
  /// Defaults to empty
  /// It is file name of remote object
  final String remoteObjectFileName;

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
        'url': url,
        'remoteUrl': remoteUrl,
        'remoteObjectFileName': remoteObjectFileName,
      }..addAll(super.toMap());
}
