
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Lambda
## version: 2015-03-31
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Lambda</fullname> <p> <b>Overview</b> </p> <p>This is the <i>AWS Lambda API Reference</i>. The AWS Lambda Developer Guide provides additional information. For the service overview, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/welcome.html">What is AWS Lambda</a>, and for information about how the service works, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-introduction.html">AWS Lambda: How it Works</a> in the <b>AWS Lambda Developer Guide</b>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/lambda/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_600437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600437): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "lambda.ap-northeast-1.amazonaws.com", "ap-southeast-1": "lambda.ap-southeast-1.amazonaws.com",
                           "us-west-2": "lambda.us-west-2.amazonaws.com",
                           "eu-west-2": "lambda.eu-west-2.amazonaws.com", "ap-northeast-3": "lambda.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "lambda.eu-central-1.amazonaws.com",
                           "us-east-2": "lambda.us-east-2.amazonaws.com",
                           "us-east-1": "lambda.us-east-1.amazonaws.com", "cn-northwest-1": "lambda.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "lambda.ap-south-1.amazonaws.com",
                           "eu-north-1": "lambda.eu-north-1.amazonaws.com", "ap-northeast-2": "lambda.ap-northeast-2.amazonaws.com",
                           "us-west-1": "lambda.us-west-1.amazonaws.com", "us-gov-east-1": "lambda.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "lambda.eu-west-3.amazonaws.com",
                           "cn-north-1": "lambda.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "lambda.sa-east-1.amazonaws.com",
                           "eu-west-1": "lambda.eu-west-1.amazonaws.com", "us-gov-west-1": "lambda.us-gov-west-1.amazonaws.com", "ap-southeast-2": "lambda.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "lambda.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "lambda.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "lambda.ap-southeast-1.amazonaws.com",
      "us-west-2": "lambda.us-west-2.amazonaws.com",
      "eu-west-2": "lambda.eu-west-2.amazonaws.com",
      "ap-northeast-3": "lambda.ap-northeast-3.amazonaws.com",
      "eu-central-1": "lambda.eu-central-1.amazonaws.com",
      "us-east-2": "lambda.us-east-2.amazonaws.com",
      "us-east-1": "lambda.us-east-1.amazonaws.com",
      "cn-northwest-1": "lambda.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "lambda.ap-south-1.amazonaws.com",
      "eu-north-1": "lambda.eu-north-1.amazonaws.com",
      "ap-northeast-2": "lambda.ap-northeast-2.amazonaws.com",
      "us-west-1": "lambda.us-west-1.amazonaws.com",
      "us-gov-east-1": "lambda.us-gov-east-1.amazonaws.com",
      "eu-west-3": "lambda.eu-west-3.amazonaws.com",
      "cn-north-1": "lambda.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "lambda.sa-east-1.amazonaws.com",
      "eu-west-1": "lambda.eu-west-1.amazonaws.com",
      "us-gov-west-1": "lambda.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "lambda.ap-southeast-2.amazonaws.com",
      "ca-central-1": "lambda.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "lambda"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddLayerVersionPermission_601045 = ref object of OpenApiRestCall_600437
proc url_AddLayerVersionPermission_601047(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LayerName" in path, "`LayerName` is a required path parameter"
  assert "VersionNumber" in path, "`VersionNumber` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-10-31/layers/"),
               (kind: VariableSegment, value: "LayerName"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "VersionNumber"),
               (kind: ConstantSegment, value: "/policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_AddLayerVersionPermission_601046(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds permissions to the resource-based policy of a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Use this action to grant layer usage permission to other accounts. You can grant permission to a single account, all AWS accounts, or all accounts in an organization.</p> <p>To revoke permission, call <a>RemoveLayerVersionPermission</a> with the statement ID that you specified when you added it.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   VersionNumber: JInt (required)
  ##                : The version number.
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `VersionNumber` field"
  var valid_601048 = path.getOrDefault("VersionNumber")
  valid_601048 = validateParameter(valid_601048, JInt, required = true, default = nil)
  if valid_601048 != nil:
    section.add "VersionNumber", valid_601048
  var valid_601049 = path.getOrDefault("LayerName")
  valid_601049 = validateParameter(valid_601049, JString, required = true,
                                 default = nil)
  if valid_601049 != nil:
    section.add "LayerName", valid_601049
  result.add "path", section
  ## parameters in `query` object:
  ##   RevisionId: JString
  ##             : Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  section = newJObject()
  var valid_601050 = query.getOrDefault("RevisionId")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "RevisionId", valid_601050
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601051 = header.getOrDefault("X-Amz-Date")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Date", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Security-Token")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Security-Token", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Content-Sha256", valid_601053
  var valid_601054 = header.getOrDefault("X-Amz-Algorithm")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Algorithm", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-Signature")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Signature", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-SignedHeaders", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Credential")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Credential", valid_601057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601059: Call_AddLayerVersionPermission_601045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds permissions to the resource-based policy of a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Use this action to grant layer usage permission to other accounts. You can grant permission to a single account, all AWS accounts, or all accounts in an organization.</p> <p>To revoke permission, call <a>RemoveLayerVersionPermission</a> with the statement ID that you specified when you added it.</p>
  ## 
  let valid = call_601059.validator(path, query, header, formData, body)
  let scheme = call_601059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601059.url(scheme.get, call_601059.host, call_601059.base,
                         call_601059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601059, url, valid)

proc call*(call_601060: Call_AddLayerVersionPermission_601045; VersionNumber: int;
          LayerName: string; body: JsonNode; RevisionId: string = ""): Recallable =
  ## addLayerVersionPermission
  ## <p>Adds permissions to the resource-based policy of a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Use this action to grant layer usage permission to other accounts. You can grant permission to a single account, all AWS accounts, or all accounts in an organization.</p> <p>To revoke permission, call <a>RemoveLayerVersionPermission</a> with the statement ID that you specified when you added it.</p>
  ##   RevisionId: string
  ##             : Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   body: JObject (required)
  var path_601061 = newJObject()
  var query_601062 = newJObject()
  var body_601063 = newJObject()
  add(query_601062, "RevisionId", newJString(RevisionId))
  add(path_601061, "VersionNumber", newJInt(VersionNumber))
  add(path_601061, "LayerName", newJString(LayerName))
  if body != nil:
    body_601063 = body
  result = call_601060.call(path_601061, query_601062, nil, nil, body_601063)

var addLayerVersionPermission* = Call_AddLayerVersionPermission_601045(
    name: "addLayerVersionPermission", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy",
    validator: validate_AddLayerVersionPermission_601046, base: "/",
    url: url_AddLayerVersionPermission_601047,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLayerVersionPolicy_600774 = ref object of OpenApiRestCall_600437
proc url_GetLayerVersionPolicy_600776(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LayerName" in path, "`LayerName` is a required path parameter"
  assert "VersionNumber" in path, "`VersionNumber` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-10-31/layers/"),
               (kind: VariableSegment, value: "LayerName"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "VersionNumber"),
               (kind: ConstantSegment, value: "/policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetLayerVersionPolicy_600775(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the permission policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   VersionNumber: JInt (required)
  ##                : The version number.
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `VersionNumber` field"
  var valid_600902 = path.getOrDefault("VersionNumber")
  valid_600902 = validateParameter(valid_600902, JInt, required = true, default = nil)
  if valid_600902 != nil:
    section.add "VersionNumber", valid_600902
  var valid_600903 = path.getOrDefault("LayerName")
  valid_600903 = validateParameter(valid_600903, JString, required = true,
                                 default = nil)
  if valid_600903 != nil:
    section.add "LayerName", valid_600903
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600904 = header.getOrDefault("X-Amz-Date")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-Date", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Security-Token")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Security-Token", valid_600905
  var valid_600906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Content-Sha256", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-Algorithm")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-Algorithm", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-Signature")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-Signature", valid_600908
  var valid_600909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600909 = validateParameter(valid_600909, JString, required = false,
                                 default = nil)
  if valid_600909 != nil:
    section.add "X-Amz-SignedHeaders", valid_600909
  var valid_600910 = header.getOrDefault("X-Amz-Credential")
  valid_600910 = validateParameter(valid_600910, JString, required = false,
                                 default = nil)
  if valid_600910 != nil:
    section.add "X-Amz-Credential", valid_600910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600933: Call_GetLayerVersionPolicy_600774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the permission policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ## 
  let valid = call_600933.validator(path, query, header, formData, body)
  let scheme = call_600933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600933.url(scheme.get, call_600933.host, call_600933.base,
                         call_600933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600933, url, valid)

proc call*(call_601004: Call_GetLayerVersionPolicy_600774; VersionNumber: int;
          LayerName: string): Recallable =
  ## getLayerVersionPolicy
  ## Returns the permission policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_601005 = newJObject()
  add(path_601005, "VersionNumber", newJInt(VersionNumber))
  add(path_601005, "LayerName", newJString(LayerName))
  result = call_601004.call(path_601005, nil, nil, nil, nil)

var getLayerVersionPolicy* = Call_GetLayerVersionPolicy_600774(
    name: "getLayerVersionPolicy", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy",
    validator: validate_GetLayerVersionPolicy_600775, base: "/",
    url: url_GetLayerVersionPolicy_600776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddPermission_601080 = ref object of OpenApiRestCall_600437
proc url_AddPermission_601082(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_AddPermission_601081(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Grants an AWS service or another account permission to use a function. You can apply the policy at the function level, or specify a qualifier to restrict access to a single version or alias. If you use a qualifier, the invoker must use the full Amazon Resource Name (ARN) of that version or alias to invoke the function.</p> <p>To grant permission to another account, specify the account ID as the <code>Principal</code>. For AWS services, the principal is a domain-style identifier defined by the service, like <code>s3.amazonaws.com</code> or <code>sns.amazonaws.com</code>. For AWS services, you can also specify the ARN or owning account of the associated resource as the <code>SourceArn</code> or <code>SourceAccount</code>. If you grant permission to a service principal without specifying the source, other accounts could potentially configure resources in their account to invoke your Lambda function.</p> <p>This action adds a statement to a resource-based permission policy for the function. For more information about function policies, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">Lambda Function Policies</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_601083 = path.getOrDefault("FunctionName")
  valid_601083 = validateParameter(valid_601083, JString, required = true,
                                 default = nil)
  if valid_601083 != nil:
    section.add "FunctionName", valid_601083
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to add permissions to a published version of the function.
  section = newJObject()
  var valid_601084 = query.getOrDefault("Qualifier")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "Qualifier", valid_601084
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601085 = header.getOrDefault("X-Amz-Date")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Date", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Security-Token")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Security-Token", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Content-Sha256", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Algorithm")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Algorithm", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Signature")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Signature", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-SignedHeaders", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Credential")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Credential", valid_601091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601093: Call_AddPermission_601080; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Grants an AWS service or another account permission to use a function. You can apply the policy at the function level, or specify a qualifier to restrict access to a single version or alias. If you use a qualifier, the invoker must use the full Amazon Resource Name (ARN) of that version or alias to invoke the function.</p> <p>To grant permission to another account, specify the account ID as the <code>Principal</code>. For AWS services, the principal is a domain-style identifier defined by the service, like <code>s3.amazonaws.com</code> or <code>sns.amazonaws.com</code>. For AWS services, you can also specify the ARN or owning account of the associated resource as the <code>SourceArn</code> or <code>SourceAccount</code>. If you grant permission to a service principal without specifying the source, other accounts could potentially configure resources in their account to invoke your Lambda function.</p> <p>This action adds a statement to a resource-based permission policy for the function. For more information about function policies, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">Lambda Function Policies</a>. </p>
  ## 
  let valid = call_601093.validator(path, query, header, formData, body)
  let scheme = call_601093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601093.url(scheme.get, call_601093.host, call_601093.base,
                         call_601093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601093, url, valid)

proc call*(call_601094: Call_AddPermission_601080; FunctionName: string;
          body: JsonNode; Qualifier: string = ""): Recallable =
  ## addPermission
  ## <p>Grants an AWS service or another account permission to use a function. You can apply the policy at the function level, or specify a qualifier to restrict access to a single version or alias. If you use a qualifier, the invoker must use the full Amazon Resource Name (ARN) of that version or alias to invoke the function.</p> <p>To grant permission to another account, specify the account ID as the <code>Principal</code>. For AWS services, the principal is a domain-style identifier defined by the service, like <code>s3.amazonaws.com</code> or <code>sns.amazonaws.com</code>. For AWS services, you can also specify the ARN or owning account of the associated resource as the <code>SourceArn</code> or <code>SourceAccount</code>. If you grant permission to a service principal without specifying the source, other accounts could potentially configure resources in their account to invoke your Lambda function.</p> <p>This action adds a statement to a resource-based permission policy for the function. For more information about function policies, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">Lambda Function Policies</a>. </p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to add permissions to a published version of the function.
  ##   body: JObject (required)
  var path_601095 = newJObject()
  var query_601096 = newJObject()
  var body_601097 = newJObject()
  add(path_601095, "FunctionName", newJString(FunctionName))
  add(query_601096, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_601097 = body
  result = call_601094.call(path_601095, query_601096, nil, nil, body_601097)

var addPermission* = Call_AddPermission_601080(name: "addPermission",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/policy",
    validator: validate_AddPermission_601081, base: "/", url: url_AddPermission_601082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPolicy_601064 = ref object of OpenApiRestCall_600437
proc url_GetPolicy_601066(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetPolicy_601065(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">resource-based IAM policy</a> for a function, version, or alias.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_601067 = path.getOrDefault("FunctionName")
  valid_601067 = validateParameter(valid_601067, JString, required = true,
                                 default = nil)
  if valid_601067 != nil:
    section.add "FunctionName", valid_601067
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to get the policy for that resource.
  section = newJObject()
  var valid_601068 = query.getOrDefault("Qualifier")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "Qualifier", valid_601068
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601069 = header.getOrDefault("X-Amz-Date")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Date", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-Security-Token")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Security-Token", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Content-Sha256", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Algorithm")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Algorithm", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Signature")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Signature", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-SignedHeaders", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Credential")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Credential", valid_601075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601076: Call_GetPolicy_601064; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">resource-based IAM policy</a> for a function, version, or alias.
  ## 
  let valid = call_601076.validator(path, query, header, formData, body)
  let scheme = call_601076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601076.url(scheme.get, call_601076.host, call_601076.base,
                         call_601076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601076, url, valid)

proc call*(call_601077: Call_GetPolicy_601064; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## getPolicy
  ## Returns the <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">resource-based IAM policy</a> for a function, version, or alias.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to get the policy for that resource.
  var path_601078 = newJObject()
  var query_601079 = newJObject()
  add(path_601078, "FunctionName", newJString(FunctionName))
  add(query_601079, "Qualifier", newJString(Qualifier))
  result = call_601077.call(path_601078, query_601079, nil, nil, nil)

var getPolicy* = Call_GetPolicy_601064(name: "getPolicy", meth: HttpMethod.HttpGet,
                                    host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/policy",
                                    validator: validate_GetPolicy_601065,
                                    base: "/", url: url_GetPolicy_601066,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlias_601116 = ref object of OpenApiRestCall_600437
proc url_CreateAlias_601118(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/aliases")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateAlias_601117(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a> for a Lambda function version. Use aliases to provide clients with a function identifier that you can update to invoke a different version.</p> <p>You can also map an alias to split invocation requests between two versions. Use the <code>RoutingConfig</code> parameter to specify a second version and the percentage of invocation requests that it receives.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_601119 = path.getOrDefault("FunctionName")
  valid_601119 = validateParameter(valid_601119, JString, required = true,
                                 default = nil)
  if valid_601119 != nil:
    section.add "FunctionName", valid_601119
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601120 = header.getOrDefault("X-Amz-Date")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Date", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-Security-Token")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Security-Token", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Content-Sha256", valid_601122
  var valid_601123 = header.getOrDefault("X-Amz-Algorithm")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-Algorithm", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-Signature")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Signature", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-SignedHeaders", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Credential")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Credential", valid_601126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601128: Call_CreateAlias_601116; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a> for a Lambda function version. Use aliases to provide clients with a function identifier that you can update to invoke a different version.</p> <p>You can also map an alias to split invocation requests between two versions. Use the <code>RoutingConfig</code> parameter to specify a second version and the percentage of invocation requests that it receives.</p>
  ## 
  let valid = call_601128.validator(path, query, header, formData, body)
  let scheme = call_601128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601128.url(scheme.get, call_601128.host, call_601128.base,
                         call_601128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601128, url, valid)

proc call*(call_601129: Call_CreateAlias_601116; FunctionName: string; body: JsonNode): Recallable =
  ## createAlias
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a> for a Lambda function version. Use aliases to provide clients with a function identifier that you can update to invoke a different version.</p> <p>You can also map an alias to split invocation requests between two versions. Use the <code>RoutingConfig</code> parameter to specify a second version and the percentage of invocation requests that it receives.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_601130 = newJObject()
  var body_601131 = newJObject()
  add(path_601130, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_601131 = body
  result = call_601129.call(path_601130, nil, nil, nil, body_601131)

var createAlias* = Call_CreateAlias_601116(name: "createAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases",
                                        validator: validate_CreateAlias_601117,
                                        base: "/", url: url_CreateAlias_601118,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAliases_601098 = ref object of OpenApiRestCall_600437
proc url_ListAliases_601100(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/aliases")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListAliases_601099(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">aliases</a> for a Lambda function.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_601101 = path.getOrDefault("FunctionName")
  valid_601101 = validateParameter(valid_601101, JString, required = true,
                                 default = nil)
  if valid_601101 != nil:
    section.add "FunctionName", valid_601101
  result.add "path", section
  ## parameters in `query` object:
  ##   FunctionVersion: JString
  ##                  : Specify a function version to only list aliases that invoke that version.
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : Limit the number of aliases returned.
  section = newJObject()
  var valid_601102 = query.getOrDefault("FunctionVersion")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "FunctionVersion", valid_601102
  var valid_601103 = query.getOrDefault("Marker")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "Marker", valid_601103
  var valid_601104 = query.getOrDefault("MaxItems")
  valid_601104 = validateParameter(valid_601104, JInt, required = false, default = nil)
  if valid_601104 != nil:
    section.add "MaxItems", valid_601104
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601105 = header.getOrDefault("X-Amz-Date")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Date", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Security-Token")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Security-Token", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Content-Sha256", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Algorithm")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Algorithm", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Signature")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Signature", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-SignedHeaders", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Credential")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Credential", valid_601111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601112: Call_ListAliases_601098; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">aliases</a> for a Lambda function.
  ## 
  let valid = call_601112.validator(path, query, header, formData, body)
  let scheme = call_601112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601112.url(scheme.get, call_601112.host, call_601112.base,
                         call_601112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601112, url, valid)

proc call*(call_601113: Call_ListAliases_601098; FunctionName: string;
          FunctionVersion: string = ""; Marker: string = ""; MaxItems: int = 0): Recallable =
  ## listAliases
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">aliases</a> for a Lambda function.
  ##   FunctionVersion: string
  ##                  : Specify a function version to only list aliases that invoke that version.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: int
  ##           : Limit the number of aliases returned.
  var path_601114 = newJObject()
  var query_601115 = newJObject()
  add(query_601115, "FunctionVersion", newJString(FunctionVersion))
  add(path_601114, "FunctionName", newJString(FunctionName))
  add(query_601115, "Marker", newJString(Marker))
  add(query_601115, "MaxItems", newJInt(MaxItems))
  result = call_601113.call(path_601114, query_601115, nil, nil, nil)

var listAliases* = Call_ListAliases_601098(name: "listAliases",
                                        meth: HttpMethod.HttpGet,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases",
                                        validator: validate_ListAliases_601099,
                                        base: "/", url: url_ListAliases_601100,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEventSourceMapping_601149 = ref object of OpenApiRestCall_600437
proc url_CreateEventSourceMapping_601151(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateEventSourceMapping_601150(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a mapping between an event source and an AWS Lambda function. Lambda reads items from the event source and triggers the function.</p> <p>For details about each event source type, see the following topics.</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html">Using AWS Lambda with Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html">Using AWS Lambda with Amazon SQS</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html">Using AWS Lambda with Amazon DynamoDB</a> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601152 = header.getOrDefault("X-Amz-Date")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Date", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-Security-Token")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-Security-Token", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Content-Sha256", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Algorithm")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Algorithm", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Signature")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Signature", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-SignedHeaders", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-Credential")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Credential", valid_601158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601160: Call_CreateEventSourceMapping_601149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a mapping between an event source and an AWS Lambda function. Lambda reads items from the event source and triggers the function.</p> <p>For details about each event source type, see the following topics.</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html">Using AWS Lambda with Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html">Using AWS Lambda with Amazon SQS</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html">Using AWS Lambda with Amazon DynamoDB</a> </p> </li> </ul>
  ## 
  let valid = call_601160.validator(path, query, header, formData, body)
  let scheme = call_601160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601160.url(scheme.get, call_601160.host, call_601160.base,
                         call_601160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601160, url, valid)

proc call*(call_601161: Call_CreateEventSourceMapping_601149; body: JsonNode): Recallable =
  ## createEventSourceMapping
  ## <p>Creates a mapping between an event source and an AWS Lambda function. Lambda reads items from the event source and triggers the function.</p> <p>For details about each event source type, see the following topics.</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html">Using AWS Lambda with Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html">Using AWS Lambda with Amazon SQS</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html">Using AWS Lambda with Amazon DynamoDB</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_601162 = newJObject()
  if body != nil:
    body_601162 = body
  result = call_601161.call(nil, nil, nil, nil, body_601162)

var createEventSourceMapping* = Call_CreateEventSourceMapping_601149(
    name: "createEventSourceMapping", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com", route: "/2015-03-31/event-source-mappings/",
    validator: validate_CreateEventSourceMapping_601150, base: "/",
    url: url_CreateEventSourceMapping_601151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventSourceMappings_601132 = ref object of OpenApiRestCall_600437
proc url_ListEventSourceMappings_601134(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListEventSourceMappings_601133(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists event source mappings. Specify an <code>EventSourceArn</code> to only show event source mappings for a single event source.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   FunctionName: JString
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Version or Alias ARN</b> - 
  ## <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction:PROD</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it's limited to 64 characters in length.</p>
  ##   EventSourceArn: JString
  ##                 : <p>The Amazon Resource Name (ARN) of the event source.</p> <ul> <li> <p> <b>Amazon Kinesis</b> - The ARN of the data stream or a stream consumer.</p> </li> <li> <p> <b>Amazon DynamoDB Streams</b> - The ARN of the stream.</p> </li> <li> <p> <b>Amazon Simple Queue Service</b> - The ARN of the queue.</p> </li> </ul>
  ##   Marker: JString
  ##         : A pagination token returned by a previous call.
  ##   MaxItems: JInt
  ##           : The maximum number of event source mappings to return.
  section = newJObject()
  var valid_601135 = query.getOrDefault("FunctionName")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "FunctionName", valid_601135
  var valid_601136 = query.getOrDefault("EventSourceArn")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "EventSourceArn", valid_601136
  var valid_601137 = query.getOrDefault("Marker")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "Marker", valid_601137
  var valid_601138 = query.getOrDefault("MaxItems")
  valid_601138 = validateParameter(valid_601138, JInt, required = false, default = nil)
  if valid_601138 != nil:
    section.add "MaxItems", valid_601138
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601139 = header.getOrDefault("X-Amz-Date")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Date", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Security-Token")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Security-Token", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Content-Sha256", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-Algorithm")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Algorithm", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Signature")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Signature", valid_601143
  var valid_601144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-SignedHeaders", valid_601144
  var valid_601145 = header.getOrDefault("X-Amz-Credential")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Credential", valid_601145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601146: Call_ListEventSourceMappings_601132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists event source mappings. Specify an <code>EventSourceArn</code> to only show event source mappings for a single event source.
  ## 
  let valid = call_601146.validator(path, query, header, formData, body)
  let scheme = call_601146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601146.url(scheme.get, call_601146.host, call_601146.base,
                         call_601146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601146, url, valid)

proc call*(call_601147: Call_ListEventSourceMappings_601132;
          FunctionName: string = ""; EventSourceArn: string = ""; Marker: string = "";
          MaxItems: int = 0): Recallable =
  ## listEventSourceMappings
  ## Lists event source mappings. Specify an <code>EventSourceArn</code> to only show event source mappings for a single event source.
  ##   FunctionName: string
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Version or Alias ARN</b> - 
  ## <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction:PROD</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it's limited to 64 characters in length.</p>
  ##   EventSourceArn: string
  ##                 : <p>The Amazon Resource Name (ARN) of the event source.</p> <ul> <li> <p> <b>Amazon Kinesis</b> - The ARN of the data stream or a stream consumer.</p> </li> <li> <p> <b>Amazon DynamoDB Streams</b> - The ARN of the stream.</p> </li> <li> <p> <b>Amazon Simple Queue Service</b> - The ARN of the queue.</p> </li> </ul>
  ##   Marker: string
  ##         : A pagination token returned by a previous call.
  ##   MaxItems: int
  ##           : The maximum number of event source mappings to return.
  var query_601148 = newJObject()
  add(query_601148, "FunctionName", newJString(FunctionName))
  add(query_601148, "EventSourceArn", newJString(EventSourceArn))
  add(query_601148, "Marker", newJString(Marker))
  add(query_601148, "MaxItems", newJInt(MaxItems))
  result = call_601147.call(nil, query_601148, nil, nil, nil)

var listEventSourceMappings* = Call_ListEventSourceMappings_601132(
    name: "listEventSourceMappings", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2015-03-31/event-source-mappings/",
    validator: validate_ListEventSourceMappings_601133, base: "/",
    url: url_ListEventSourceMappings_601134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunction_601163 = ref object of OpenApiRestCall_600437
proc url_CreateFunction_601165(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateFunction_601164(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a Lambda function. To create a function, you need a <a href="https://docs.aws.amazon.com/lambda/latest/dg/deployment-package-v2.html">deployment package</a> and an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role">execution role</a>. The deployment package contains your function code. The execution role grants the function permission to use AWS services, such as Amazon CloudWatch Logs for log streaming and AWS X-Ray for request tracing.</p> <p>A function has an unpublished version, and can have published versions and aliases. The unpublished version changes when you update your function's code and configuration. A published version is a snapshot of your function code and configuration that can't be changed. An alias is a named resource that maps to a version, and can be changed to map to a different version. Use the <code>Publish</code> parameter to create version <code>1</code> of your function from its initial configuration.</p> <p>The other parameters let you configure version-specific and function-level settings. You can modify version-specific settings later with <a>UpdateFunctionConfiguration</a>. Function-level settings apply to both the unpublished and published versions of the function, and include tags (<a>TagResource</a>) and per-function concurrency limits (<a>PutFunctionConcurrency</a>).</p> <p>If another account or an AWS service invokes your function, use <a>AddPermission</a> to grant permission by creating a resource-based IAM policy. You can grant permissions at the function level, on a version, or on an alias.</p> <p>To invoke your function directly, use <a>Invoke</a>. To invoke your function in response to events in other AWS services, create an event source mapping (<a>CreateEventSourceMapping</a>), or configure a function trigger in the other service. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/invoking-lambda-functions.html">Invoking Functions</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601166 = header.getOrDefault("X-Amz-Date")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Date", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Security-Token")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Security-Token", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Content-Sha256", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Algorithm")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Algorithm", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Signature")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Signature", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-SignedHeaders", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-Credential")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Credential", valid_601172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601174: Call_CreateFunction_601163; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Lambda function. To create a function, you need a <a href="https://docs.aws.amazon.com/lambda/latest/dg/deployment-package-v2.html">deployment package</a> and an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role">execution role</a>. The deployment package contains your function code. The execution role grants the function permission to use AWS services, such as Amazon CloudWatch Logs for log streaming and AWS X-Ray for request tracing.</p> <p>A function has an unpublished version, and can have published versions and aliases. The unpublished version changes when you update your function's code and configuration. A published version is a snapshot of your function code and configuration that can't be changed. An alias is a named resource that maps to a version, and can be changed to map to a different version. Use the <code>Publish</code> parameter to create version <code>1</code> of your function from its initial configuration.</p> <p>The other parameters let you configure version-specific and function-level settings. You can modify version-specific settings later with <a>UpdateFunctionConfiguration</a>. Function-level settings apply to both the unpublished and published versions of the function, and include tags (<a>TagResource</a>) and per-function concurrency limits (<a>PutFunctionConcurrency</a>).</p> <p>If another account or an AWS service invokes your function, use <a>AddPermission</a> to grant permission by creating a resource-based IAM policy. You can grant permissions at the function level, on a version, or on an alias.</p> <p>To invoke your function directly, use <a>Invoke</a>. To invoke your function in response to events in other AWS services, create an event source mapping (<a>CreateEventSourceMapping</a>), or configure a function trigger in the other service. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/invoking-lambda-functions.html">Invoking Functions</a>.</p>
  ## 
  let valid = call_601174.validator(path, query, header, formData, body)
  let scheme = call_601174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601174.url(scheme.get, call_601174.host, call_601174.base,
                         call_601174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601174, url, valid)

proc call*(call_601175: Call_CreateFunction_601163; body: JsonNode): Recallable =
  ## createFunction
  ## <p>Creates a Lambda function. To create a function, you need a <a href="https://docs.aws.amazon.com/lambda/latest/dg/deployment-package-v2.html">deployment package</a> and an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role">execution role</a>. The deployment package contains your function code. The execution role grants the function permission to use AWS services, such as Amazon CloudWatch Logs for log streaming and AWS X-Ray for request tracing.</p> <p>A function has an unpublished version, and can have published versions and aliases. The unpublished version changes when you update your function's code and configuration. A published version is a snapshot of your function code and configuration that can't be changed. An alias is a named resource that maps to a version, and can be changed to map to a different version. Use the <code>Publish</code> parameter to create version <code>1</code> of your function from its initial configuration.</p> <p>The other parameters let you configure version-specific and function-level settings. You can modify version-specific settings later with <a>UpdateFunctionConfiguration</a>. Function-level settings apply to both the unpublished and published versions of the function, and include tags (<a>TagResource</a>) and per-function concurrency limits (<a>PutFunctionConcurrency</a>).</p> <p>If another account or an AWS service invokes your function, use <a>AddPermission</a> to grant permission by creating a resource-based IAM policy. You can grant permissions at the function level, on a version, or on an alias.</p> <p>To invoke your function directly, use <a>Invoke</a>. To invoke your function in response to events in other AWS services, create an event source mapping (<a>CreateEventSourceMapping</a>), or configure a function trigger in the other service. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/invoking-lambda-functions.html">Invoking Functions</a>.</p>
  ##   body: JObject (required)
  var body_601176 = newJObject()
  if body != nil:
    body_601176 = body
  result = call_601175.call(nil, nil, nil, nil, body_601176)

var createFunction* = Call_CreateFunction_601163(name: "createFunction",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions", validator: validate_CreateFunction_601164,
    base: "/", url: url_CreateFunction_601165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAlias_601192 = ref object of OpenApiRestCall_600437
proc url_UpdateAlias_601194(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  assert "Name" in path, "`Name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/aliases/"),
               (kind: VariableSegment, value: "Name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateAlias_601193(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the configuration of a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: JString (required)
  ##       : The name of the alias.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_601195 = path.getOrDefault("FunctionName")
  valid_601195 = validateParameter(valid_601195, JString, required = true,
                                 default = nil)
  if valid_601195 != nil:
    section.add "FunctionName", valid_601195
  var valid_601196 = path.getOrDefault("Name")
  valid_601196 = validateParameter(valid_601196, JString, required = true,
                                 default = nil)
  if valid_601196 != nil:
    section.add "Name", valid_601196
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601197 = header.getOrDefault("X-Amz-Date")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Date", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Security-Token")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Security-Token", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Content-Sha256", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Algorithm")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Algorithm", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Signature")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Signature", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-SignedHeaders", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Credential")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Credential", valid_601203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601205: Call_UpdateAlias_601192; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration of a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  let valid = call_601205.validator(path, query, header, formData, body)
  let scheme = call_601205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601205.url(scheme.get, call_601205.host, call_601205.base,
                         call_601205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601205, url, valid)

proc call*(call_601206: Call_UpdateAlias_601192; FunctionName: string; Name: string;
          body: JsonNode): Recallable =
  ## updateAlias
  ## Updates the configuration of a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: string (required)
  ##       : The name of the alias.
  ##   body: JObject (required)
  var path_601207 = newJObject()
  var body_601208 = newJObject()
  add(path_601207, "FunctionName", newJString(FunctionName))
  add(path_601207, "Name", newJString(Name))
  if body != nil:
    body_601208 = body
  result = call_601206.call(path_601207, nil, nil, nil, body_601208)

var updateAlias* = Call_UpdateAlias_601192(name: "updateAlias",
                                        meth: HttpMethod.HttpPut,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases/{Name}",
                                        validator: validate_UpdateAlias_601193,
                                        base: "/", url: url_UpdateAlias_601194,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAlias_601177 = ref object of OpenApiRestCall_600437
proc url_GetAlias_601179(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  assert "Name" in path, "`Name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/aliases/"),
               (kind: VariableSegment, value: "Name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetAlias_601178(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns details about a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: JString (required)
  ##       : The name of the alias.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_601180 = path.getOrDefault("FunctionName")
  valid_601180 = validateParameter(valid_601180, JString, required = true,
                                 default = nil)
  if valid_601180 != nil:
    section.add "FunctionName", valid_601180
  var valid_601181 = path.getOrDefault("Name")
  valid_601181 = validateParameter(valid_601181, JString, required = true,
                                 default = nil)
  if valid_601181 != nil:
    section.add "Name", valid_601181
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601182 = header.getOrDefault("X-Amz-Date")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Date", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Security-Token")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Security-Token", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Content-Sha256", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Algorithm")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Algorithm", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Signature")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Signature", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-SignedHeaders", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Credential")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Credential", valid_601188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601189: Call_GetAlias_601177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  let valid = call_601189.validator(path, query, header, formData, body)
  let scheme = call_601189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601189.url(scheme.get, call_601189.host, call_601189.base,
                         call_601189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601189, url, valid)

proc call*(call_601190: Call_GetAlias_601177; FunctionName: string; Name: string): Recallable =
  ## getAlias
  ## Returns details about a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: string (required)
  ##       : The name of the alias.
  var path_601191 = newJObject()
  add(path_601191, "FunctionName", newJString(FunctionName))
  add(path_601191, "Name", newJString(Name))
  result = call_601190.call(path_601191, nil, nil, nil, nil)

var getAlias* = Call_GetAlias_601177(name: "getAlias", meth: HttpMethod.HttpGet,
                                  host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases/{Name}",
                                  validator: validate_GetAlias_601178, base: "/",
                                  url: url_GetAlias_601179,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlias_601209 = ref object of OpenApiRestCall_600437
proc url_DeleteAlias_601211(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  assert "Name" in path, "`Name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/aliases/"),
               (kind: VariableSegment, value: "Name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteAlias_601210(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: JString (required)
  ##       : The name of the alias.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_601212 = path.getOrDefault("FunctionName")
  valid_601212 = validateParameter(valid_601212, JString, required = true,
                                 default = nil)
  if valid_601212 != nil:
    section.add "FunctionName", valid_601212
  var valid_601213 = path.getOrDefault("Name")
  valid_601213 = validateParameter(valid_601213, JString, required = true,
                                 default = nil)
  if valid_601213 != nil:
    section.add "Name", valid_601213
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601214 = header.getOrDefault("X-Amz-Date")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Date", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-Security-Token")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Security-Token", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Content-Sha256", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-Algorithm")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Algorithm", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Signature")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Signature", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-SignedHeaders", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-Credential")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Credential", valid_601220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601221: Call_DeleteAlias_601209; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  let valid = call_601221.validator(path, query, header, formData, body)
  let scheme = call_601221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601221.url(scheme.get, call_601221.host, call_601221.base,
                         call_601221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601221, url, valid)

proc call*(call_601222: Call_DeleteAlias_601209; FunctionName: string; Name: string): Recallable =
  ## deleteAlias
  ## Deletes a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: string (required)
  ##       : The name of the alias.
  var path_601223 = newJObject()
  add(path_601223, "FunctionName", newJString(FunctionName))
  add(path_601223, "Name", newJString(Name))
  result = call_601222.call(path_601223, nil, nil, nil, nil)

var deleteAlias* = Call_DeleteAlias_601209(name: "deleteAlias",
                                        meth: HttpMethod.HttpDelete,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases/{Name}",
                                        validator: validate_DeleteAlias_601210,
                                        base: "/", url: url_DeleteAlias_601211,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEventSourceMapping_601238 = ref object of OpenApiRestCall_600437
proc url_UpdateEventSourceMapping_601240(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "UUID" in path, "`UUID` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/event-source-mappings/"),
               (kind: VariableSegment, value: "UUID")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateEventSourceMapping_601239(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an event source mapping. You can change the function that AWS Lambda invokes, or pause invocation and resume later from the same location.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UUID: JString (required)
  ##       : The identifier of the event source mapping.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UUID` field"
  var valid_601241 = path.getOrDefault("UUID")
  valid_601241 = validateParameter(valid_601241, JString, required = true,
                                 default = nil)
  if valid_601241 != nil:
    section.add "UUID", valid_601241
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601242 = header.getOrDefault("X-Amz-Date")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Date", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-Security-Token")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Security-Token", valid_601243
  var valid_601244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Content-Sha256", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Algorithm")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Algorithm", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Signature")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Signature", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-SignedHeaders", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-Credential")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Credential", valid_601248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601250: Call_UpdateEventSourceMapping_601238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an event source mapping. You can change the function that AWS Lambda invokes, or pause invocation and resume later from the same location.
  ## 
  let valid = call_601250.validator(path, query, header, formData, body)
  let scheme = call_601250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601250.url(scheme.get, call_601250.host, call_601250.base,
                         call_601250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601250, url, valid)

proc call*(call_601251: Call_UpdateEventSourceMapping_601238; UUID: string;
          body: JsonNode): Recallable =
  ## updateEventSourceMapping
  ## Updates an event source mapping. You can change the function that AWS Lambda invokes, or pause invocation and resume later from the same location.
  ##   UUID: string (required)
  ##       : The identifier of the event source mapping.
  ##   body: JObject (required)
  var path_601252 = newJObject()
  var body_601253 = newJObject()
  add(path_601252, "UUID", newJString(UUID))
  if body != nil:
    body_601253 = body
  result = call_601251.call(path_601252, nil, nil, nil, body_601253)

var updateEventSourceMapping* = Call_UpdateEventSourceMapping_601238(
    name: "updateEventSourceMapping", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/event-source-mappings/{UUID}",
    validator: validate_UpdateEventSourceMapping_601239, base: "/",
    url: url_UpdateEventSourceMapping_601240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventSourceMapping_601224 = ref object of OpenApiRestCall_600437
proc url_GetEventSourceMapping_601226(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "UUID" in path, "`UUID` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/event-source-mappings/"),
               (kind: VariableSegment, value: "UUID")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetEventSourceMapping_601225(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns details about an event source mapping. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UUID: JString (required)
  ##       : The identifier of the event source mapping.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UUID` field"
  var valid_601227 = path.getOrDefault("UUID")
  valid_601227 = validateParameter(valid_601227, JString, required = true,
                                 default = nil)
  if valid_601227 != nil:
    section.add "UUID", valid_601227
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601228 = header.getOrDefault("X-Amz-Date")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-Date", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-Security-Token")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Security-Token", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Content-Sha256", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Algorithm")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Algorithm", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Signature")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Signature", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-SignedHeaders", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Credential")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Credential", valid_601234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601235: Call_GetEventSourceMapping_601224; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about an event source mapping. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.
  ## 
  let valid = call_601235.validator(path, query, header, formData, body)
  let scheme = call_601235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601235.url(scheme.get, call_601235.host, call_601235.base,
                         call_601235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601235, url, valid)

proc call*(call_601236: Call_GetEventSourceMapping_601224; UUID: string): Recallable =
  ## getEventSourceMapping
  ## Returns details about an event source mapping. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.
  ##   UUID: string (required)
  ##       : The identifier of the event source mapping.
  var path_601237 = newJObject()
  add(path_601237, "UUID", newJString(UUID))
  result = call_601236.call(path_601237, nil, nil, nil, nil)

var getEventSourceMapping* = Call_GetEventSourceMapping_601224(
    name: "getEventSourceMapping", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/event-source-mappings/{UUID}",
    validator: validate_GetEventSourceMapping_601225, base: "/",
    url: url_GetEventSourceMapping_601226, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventSourceMapping_601254 = ref object of OpenApiRestCall_600437
proc url_DeleteEventSourceMapping_601256(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "UUID" in path, "`UUID` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/event-source-mappings/"),
               (kind: VariableSegment, value: "UUID")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteEventSourceMapping_601255(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html">event source mapping</a>. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UUID: JString (required)
  ##       : The identifier of the event source mapping.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UUID` field"
  var valid_601257 = path.getOrDefault("UUID")
  valid_601257 = validateParameter(valid_601257, JString, required = true,
                                 default = nil)
  if valid_601257 != nil:
    section.add "UUID", valid_601257
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601258 = header.getOrDefault("X-Amz-Date")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Date", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-Security-Token")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Security-Token", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Content-Sha256", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-Algorithm")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Algorithm", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Signature")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Signature", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-SignedHeaders", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Credential")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Credential", valid_601264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601265: Call_DeleteEventSourceMapping_601254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html">event source mapping</a>. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.
  ## 
  let valid = call_601265.validator(path, query, header, formData, body)
  let scheme = call_601265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601265.url(scheme.get, call_601265.host, call_601265.base,
                         call_601265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601265, url, valid)

proc call*(call_601266: Call_DeleteEventSourceMapping_601254; UUID: string): Recallable =
  ## deleteEventSourceMapping
  ## Deletes an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html">event source mapping</a>. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.
  ##   UUID: string (required)
  ##       : The identifier of the event source mapping.
  var path_601267 = newJObject()
  add(path_601267, "UUID", newJString(UUID))
  result = call_601266.call(path_601267, nil, nil, nil, nil)

var deleteEventSourceMapping* = Call_DeleteEventSourceMapping_601254(
    name: "deleteEventSourceMapping", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/event-source-mappings/{UUID}",
    validator: validate_DeleteEventSourceMapping_601255, base: "/",
    url: url_DeleteEventSourceMapping_601256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunction_601268 = ref object of OpenApiRestCall_600437
proc url_GetFunction_601270(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetFunction_601269(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about the function or function version, with a link to download the deployment package that's valid for 10 minutes. If you specify a function version, only details that are specific to that version are returned.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_601271 = path.getOrDefault("FunctionName")
  valid_601271 = validateParameter(valid_601271, JString, required = true,
                                 default = nil)
  if valid_601271 != nil:
    section.add "FunctionName", valid_601271
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to get details about a published version of the function.
  section = newJObject()
  var valid_601272 = query.getOrDefault("Qualifier")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "Qualifier", valid_601272
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601273 = header.getOrDefault("X-Amz-Date")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Date", valid_601273
  var valid_601274 = header.getOrDefault("X-Amz-Security-Token")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "X-Amz-Security-Token", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Content-Sha256", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-Algorithm")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Algorithm", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-Signature")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Signature", valid_601277
  var valid_601278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-SignedHeaders", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-Credential")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Credential", valid_601279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601280: Call_GetFunction_601268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the function or function version, with a link to download the deployment package that's valid for 10 minutes. If you specify a function version, only details that are specific to that version are returned.
  ## 
  let valid = call_601280.validator(path, query, header, formData, body)
  let scheme = call_601280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601280.url(scheme.get, call_601280.host, call_601280.base,
                         call_601280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601280, url, valid)

proc call*(call_601281: Call_GetFunction_601268; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## getFunction
  ## Returns information about the function or function version, with a link to download the deployment package that's valid for 10 minutes. If you specify a function version, only details that are specific to that version are returned.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to get details about a published version of the function.
  var path_601282 = newJObject()
  var query_601283 = newJObject()
  add(path_601282, "FunctionName", newJString(FunctionName))
  add(query_601283, "Qualifier", newJString(Qualifier))
  result = call_601281.call(path_601282, query_601283, nil, nil, nil)

var getFunction* = Call_GetFunction_601268(name: "getFunction",
                                        meth: HttpMethod.HttpGet,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}",
                                        validator: validate_GetFunction_601269,
                                        base: "/", url: url_GetFunction_601270,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunction_601284 = ref object of OpenApiRestCall_600437
proc url_DeleteFunction_601286(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteFunction_601285(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes a Lambda function. To delete a specific function version, use the <code>Qualifier</code> parameter. Otherwise, all versions and aliases are deleted.</p> <p>To delete Lambda event source mappings that invoke a function, use <a>DeleteEventSourceMapping</a>. For AWS services and resources that invoke your function directly, delete the trigger in the service where you originally configured it.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function or version.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:1</code> (with version).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_601287 = path.getOrDefault("FunctionName")
  valid_601287 = validateParameter(valid_601287, JString, required = true,
                                 default = nil)
  if valid_601287 != nil:
    section.add "FunctionName", valid_601287
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version to delete. You can't delete a version that's referenced by an alias.
  section = newJObject()
  var valid_601288 = query.getOrDefault("Qualifier")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "Qualifier", valid_601288
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601289 = header.getOrDefault("X-Amz-Date")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Date", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Security-Token")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Security-Token", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Content-Sha256", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Algorithm")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Algorithm", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Signature")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Signature", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-SignedHeaders", valid_601294
  var valid_601295 = header.getOrDefault("X-Amz-Credential")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Credential", valid_601295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601296: Call_DeleteFunction_601284; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a Lambda function. To delete a specific function version, use the <code>Qualifier</code> parameter. Otherwise, all versions and aliases are deleted.</p> <p>To delete Lambda event source mappings that invoke a function, use <a>DeleteEventSourceMapping</a>. For AWS services and resources that invoke your function directly, delete the trigger in the service where you originally configured it.</p>
  ## 
  let valid = call_601296.validator(path, query, header, formData, body)
  let scheme = call_601296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601296.url(scheme.get, call_601296.host, call_601296.base,
                         call_601296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601296, url, valid)

proc call*(call_601297: Call_DeleteFunction_601284; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## deleteFunction
  ## <p>Deletes a Lambda function. To delete a specific function version, use the <code>Qualifier</code> parameter. Otherwise, all versions and aliases are deleted.</p> <p>To delete Lambda event source mappings that invoke a function, use <a>DeleteEventSourceMapping</a>. For AWS services and resources that invoke your function directly, delete the trigger in the service where you originally configured it.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function or version.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:1</code> (with version).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version to delete. You can't delete a version that's referenced by an alias.
  var path_601298 = newJObject()
  var query_601299 = newJObject()
  add(path_601298, "FunctionName", newJString(FunctionName))
  add(query_601299, "Qualifier", newJString(Qualifier))
  result = call_601297.call(path_601298, query_601299, nil, nil, nil)

var deleteFunction* = Call_DeleteFunction_601284(name: "deleteFunction",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}",
    validator: validate_DeleteFunction_601285, base: "/", url: url_DeleteFunction_601286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFunctionConcurrency_601300 = ref object of OpenApiRestCall_600437
proc url_PutFunctionConcurrency_601302(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-10-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/concurrency")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutFunctionConcurrency_601301(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the maximum number of simultaneous executions for a function, and reserves capacity for that concurrency level.</p> <p>Concurrency settings apply to the function as a whole, including all published versions and the unpublished version. Reserving concurrency both ensures that your function has capacity to process the specified number of events simultaneously, and prevents it from scaling beyond that level. Use <a>GetFunction</a> to see the current setting for a function.</p> <p>Use <a>GetAccountSettings</a> to see your regional concurrency limit. You can reserve concurrency for as many functions as you like, as long as you leave at least 100 simultaneous executions unreserved for functions that aren't configured with a per-function limit. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/concurrent-executions.html">Managing Concurrency</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_601303 = path.getOrDefault("FunctionName")
  valid_601303 = validateParameter(valid_601303, JString, required = true,
                                 default = nil)
  if valid_601303 != nil:
    section.add "FunctionName", valid_601303
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601304 = header.getOrDefault("X-Amz-Date")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-Date", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-Security-Token")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Security-Token", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Content-Sha256", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Algorithm")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Algorithm", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-Signature")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Signature", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-SignedHeaders", valid_601309
  var valid_601310 = header.getOrDefault("X-Amz-Credential")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Credential", valid_601310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601312: Call_PutFunctionConcurrency_601300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the maximum number of simultaneous executions for a function, and reserves capacity for that concurrency level.</p> <p>Concurrency settings apply to the function as a whole, including all published versions and the unpublished version. Reserving concurrency both ensures that your function has capacity to process the specified number of events simultaneously, and prevents it from scaling beyond that level. Use <a>GetFunction</a> to see the current setting for a function.</p> <p>Use <a>GetAccountSettings</a> to see your regional concurrency limit. You can reserve concurrency for as many functions as you like, as long as you leave at least 100 simultaneous executions unreserved for functions that aren't configured with a per-function limit. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/concurrent-executions.html">Managing Concurrency</a>.</p>
  ## 
  let valid = call_601312.validator(path, query, header, formData, body)
  let scheme = call_601312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601312.url(scheme.get, call_601312.host, call_601312.base,
                         call_601312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601312, url, valid)

proc call*(call_601313: Call_PutFunctionConcurrency_601300; FunctionName: string;
          body: JsonNode): Recallable =
  ## putFunctionConcurrency
  ## <p>Sets the maximum number of simultaneous executions for a function, and reserves capacity for that concurrency level.</p> <p>Concurrency settings apply to the function as a whole, including all published versions and the unpublished version. Reserving concurrency both ensures that your function has capacity to process the specified number of events simultaneously, and prevents it from scaling beyond that level. Use <a>GetFunction</a> to see the current setting for a function.</p> <p>Use <a>GetAccountSettings</a> to see your regional concurrency limit. You can reserve concurrency for as many functions as you like, as long as you leave at least 100 simultaneous executions unreserved for functions that aren't configured with a per-function limit. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/concurrent-executions.html">Managing Concurrency</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_601314 = newJObject()
  var body_601315 = newJObject()
  add(path_601314, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_601315 = body
  result = call_601313.call(path_601314, nil, nil, nil, body_601315)

var putFunctionConcurrency* = Call_PutFunctionConcurrency_601300(
    name: "putFunctionConcurrency", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2017-10-31/functions/{FunctionName}/concurrency",
    validator: validate_PutFunctionConcurrency_601301, base: "/",
    url: url_PutFunctionConcurrency_601302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionConcurrency_601316 = ref object of OpenApiRestCall_600437
proc url_DeleteFunctionConcurrency_601318(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-10-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/concurrency")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteFunctionConcurrency_601317(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a concurrent execution limit from a function.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_601319 = path.getOrDefault("FunctionName")
  valid_601319 = validateParameter(valid_601319, JString, required = true,
                                 default = nil)
  if valid_601319 != nil:
    section.add "FunctionName", valid_601319
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601320 = header.getOrDefault("X-Amz-Date")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "X-Amz-Date", valid_601320
  var valid_601321 = header.getOrDefault("X-Amz-Security-Token")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-Security-Token", valid_601321
  var valid_601322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-Content-Sha256", valid_601322
  var valid_601323 = header.getOrDefault("X-Amz-Algorithm")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-Algorithm", valid_601323
  var valid_601324 = header.getOrDefault("X-Amz-Signature")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Signature", valid_601324
  var valid_601325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-SignedHeaders", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-Credential")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Credential", valid_601326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601327: Call_DeleteFunctionConcurrency_601316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a concurrent execution limit from a function.
  ## 
  let valid = call_601327.validator(path, query, header, formData, body)
  let scheme = call_601327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601327.url(scheme.get, call_601327.host, call_601327.base,
                         call_601327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601327, url, valid)

proc call*(call_601328: Call_DeleteFunctionConcurrency_601316; FunctionName: string): Recallable =
  ## deleteFunctionConcurrency
  ## Removes a concurrent execution limit from a function.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  var path_601329 = newJObject()
  add(path_601329, "FunctionName", newJString(FunctionName))
  result = call_601328.call(path_601329, nil, nil, nil, nil)

var deleteFunctionConcurrency* = Call_DeleteFunctionConcurrency_601316(
    name: "deleteFunctionConcurrency", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2017-10-31/functions/{FunctionName}/concurrency",
    validator: validate_DeleteFunctionConcurrency_601317, base: "/",
    url: url_DeleteFunctionConcurrency_601318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLayerVersion_601330 = ref object of OpenApiRestCall_600437
proc url_GetLayerVersion_601332(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LayerName" in path, "`LayerName` is a required path parameter"
  assert "VersionNumber" in path, "`VersionNumber` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-10-31/layers/"),
               (kind: VariableSegment, value: "LayerName"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "VersionNumber")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetLayerVersion_601331(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   VersionNumber: JInt (required)
  ##                : The version number.
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `VersionNumber` field"
  var valid_601333 = path.getOrDefault("VersionNumber")
  valid_601333 = validateParameter(valid_601333, JInt, required = true, default = nil)
  if valid_601333 != nil:
    section.add "VersionNumber", valid_601333
  var valid_601334 = path.getOrDefault("LayerName")
  valid_601334 = validateParameter(valid_601334, JString, required = true,
                                 default = nil)
  if valid_601334 != nil:
    section.add "LayerName", valid_601334
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601335 = header.getOrDefault("X-Amz-Date")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-Date", valid_601335
  var valid_601336 = header.getOrDefault("X-Amz-Security-Token")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-Security-Token", valid_601336
  var valid_601337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-Content-Sha256", valid_601337
  var valid_601338 = header.getOrDefault("X-Amz-Algorithm")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-Algorithm", valid_601338
  var valid_601339 = header.getOrDefault("X-Amz-Signature")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "X-Amz-Signature", valid_601339
  var valid_601340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-SignedHeaders", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-Credential")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Credential", valid_601341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601342: Call_GetLayerVersion_601330; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ## 
  let valid = call_601342.validator(path, query, header, formData, body)
  let scheme = call_601342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601342.url(scheme.get, call_601342.host, call_601342.base,
                         call_601342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601342, url, valid)

proc call*(call_601343: Call_GetLayerVersion_601330; VersionNumber: int;
          LayerName: string): Recallable =
  ## getLayerVersion
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_601344 = newJObject()
  add(path_601344, "VersionNumber", newJInt(VersionNumber))
  add(path_601344, "LayerName", newJString(LayerName))
  result = call_601343.call(path_601344, nil, nil, nil, nil)

var getLayerVersion* = Call_GetLayerVersion_601330(name: "getLayerVersion",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}",
    validator: validate_GetLayerVersion_601331, base: "/", url: url_GetLayerVersion_601332,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLayerVersion_601345 = ref object of OpenApiRestCall_600437
proc url_DeleteLayerVersion_601347(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LayerName" in path, "`LayerName` is a required path parameter"
  assert "VersionNumber" in path, "`VersionNumber` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-10-31/layers/"),
               (kind: VariableSegment, value: "LayerName"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "VersionNumber")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteLayerVersion_601346(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Deleted versions can no longer be viewed or added to functions. To avoid breaking functions, a copy of the version remains in Lambda until no functions refer to it.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   VersionNumber: JInt (required)
  ##                : The version number.
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `VersionNumber` field"
  var valid_601348 = path.getOrDefault("VersionNumber")
  valid_601348 = validateParameter(valid_601348, JInt, required = true, default = nil)
  if valid_601348 != nil:
    section.add "VersionNumber", valid_601348
  var valid_601349 = path.getOrDefault("LayerName")
  valid_601349 = validateParameter(valid_601349, JString, required = true,
                                 default = nil)
  if valid_601349 != nil:
    section.add "LayerName", valid_601349
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601350 = header.getOrDefault("X-Amz-Date")
  valid_601350 = validateParameter(valid_601350, JString, required = false,
                                 default = nil)
  if valid_601350 != nil:
    section.add "X-Amz-Date", valid_601350
  var valid_601351 = header.getOrDefault("X-Amz-Security-Token")
  valid_601351 = validateParameter(valid_601351, JString, required = false,
                                 default = nil)
  if valid_601351 != nil:
    section.add "X-Amz-Security-Token", valid_601351
  var valid_601352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-Content-Sha256", valid_601352
  var valid_601353 = header.getOrDefault("X-Amz-Algorithm")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "X-Amz-Algorithm", valid_601353
  var valid_601354 = header.getOrDefault("X-Amz-Signature")
  valid_601354 = validateParameter(valid_601354, JString, required = false,
                                 default = nil)
  if valid_601354 != nil:
    section.add "X-Amz-Signature", valid_601354
  var valid_601355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-SignedHeaders", valid_601355
  var valid_601356 = header.getOrDefault("X-Amz-Credential")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-Credential", valid_601356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601357: Call_DeleteLayerVersion_601345; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Deleted versions can no longer be viewed or added to functions. To avoid breaking functions, a copy of the version remains in Lambda until no functions refer to it.
  ## 
  let valid = call_601357.validator(path, query, header, formData, body)
  let scheme = call_601357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601357.url(scheme.get, call_601357.host, call_601357.base,
                         call_601357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601357, url, valid)

proc call*(call_601358: Call_DeleteLayerVersion_601345; VersionNumber: int;
          LayerName: string): Recallable =
  ## deleteLayerVersion
  ## Deletes a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Deleted versions can no longer be viewed or added to functions. To avoid breaking functions, a copy of the version remains in Lambda until no functions refer to it.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_601359 = newJObject()
  add(path_601359, "VersionNumber", newJInt(VersionNumber))
  add(path_601359, "LayerName", newJString(LayerName))
  result = call_601358.call(path_601359, nil, nil, nil, nil)

var deleteLayerVersion* = Call_DeleteLayerVersion_601345(
    name: "deleteLayerVersion", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}",
    validator: validate_DeleteLayerVersion_601346, base: "/",
    url: url_DeleteLayerVersion_601347, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_601360 = ref object of OpenApiRestCall_600437
proc url_GetAccountSettings_601362(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAccountSettings_601361(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Retrieves details about your account's <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limits</a> and usage in an AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601363 = header.getOrDefault("X-Amz-Date")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-Date", valid_601363
  var valid_601364 = header.getOrDefault("X-Amz-Security-Token")
  valid_601364 = validateParameter(valid_601364, JString, required = false,
                                 default = nil)
  if valid_601364 != nil:
    section.add "X-Amz-Security-Token", valid_601364
  var valid_601365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "X-Amz-Content-Sha256", valid_601365
  var valid_601366 = header.getOrDefault("X-Amz-Algorithm")
  valid_601366 = validateParameter(valid_601366, JString, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "X-Amz-Algorithm", valid_601366
  var valid_601367 = header.getOrDefault("X-Amz-Signature")
  valid_601367 = validateParameter(valid_601367, JString, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "X-Amz-Signature", valid_601367
  var valid_601368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-SignedHeaders", valid_601368
  var valid_601369 = header.getOrDefault("X-Amz-Credential")
  valid_601369 = validateParameter(valid_601369, JString, required = false,
                                 default = nil)
  if valid_601369 != nil:
    section.add "X-Amz-Credential", valid_601369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601370: Call_GetAccountSettings_601360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details about your account's <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limits</a> and usage in an AWS Region.
  ## 
  let valid = call_601370.validator(path, query, header, formData, body)
  let scheme = call_601370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601370.url(scheme.get, call_601370.host, call_601370.base,
                         call_601370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601370, url, valid)

proc call*(call_601371: Call_GetAccountSettings_601360): Recallable =
  ## getAccountSettings
  ## Retrieves details about your account's <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limits</a> and usage in an AWS Region.
  result = call_601371.call(nil, nil, nil, nil, nil)

var getAccountSettings* = Call_GetAccountSettings_601360(
    name: "getAccountSettings", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2016-08-19/account-settings/",
    validator: validate_GetAccountSettings_601361, base: "/",
    url: url_GetAccountSettings_601362, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionConfiguration_601388 = ref object of OpenApiRestCall_600437
proc url_UpdateFunctionConfiguration_601390(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateFunctionConfiguration_601389(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modify the version-specific settings of a Lambda function.</p> <p>These settings can vary between versions of a function and are locked when you publish a version. You can't modify the configuration of a published version, only the unpublished version.</p> <p>To configure function concurrency, use <a>PutFunctionConcurrency</a>. To grant invoke permissions to an account or AWS service, use <a>AddPermission</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_601391 = path.getOrDefault("FunctionName")
  valid_601391 = validateParameter(valid_601391, JString, required = true,
                                 default = nil)
  if valid_601391 != nil:
    section.add "FunctionName", valid_601391
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601392 = header.getOrDefault("X-Amz-Date")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-Date", valid_601392
  var valid_601393 = header.getOrDefault("X-Amz-Security-Token")
  valid_601393 = validateParameter(valid_601393, JString, required = false,
                                 default = nil)
  if valid_601393 != nil:
    section.add "X-Amz-Security-Token", valid_601393
  var valid_601394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601394 = validateParameter(valid_601394, JString, required = false,
                                 default = nil)
  if valid_601394 != nil:
    section.add "X-Amz-Content-Sha256", valid_601394
  var valid_601395 = header.getOrDefault("X-Amz-Algorithm")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Algorithm", valid_601395
  var valid_601396 = header.getOrDefault("X-Amz-Signature")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-Signature", valid_601396
  var valid_601397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-SignedHeaders", valid_601397
  var valid_601398 = header.getOrDefault("X-Amz-Credential")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Credential", valid_601398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601400: Call_UpdateFunctionConfiguration_601388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modify the version-specific settings of a Lambda function.</p> <p>These settings can vary between versions of a function and are locked when you publish a version. You can't modify the configuration of a published version, only the unpublished version.</p> <p>To configure function concurrency, use <a>PutFunctionConcurrency</a>. To grant invoke permissions to an account or AWS service, use <a>AddPermission</a>.</p>
  ## 
  let valid = call_601400.validator(path, query, header, formData, body)
  let scheme = call_601400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601400.url(scheme.get, call_601400.host, call_601400.base,
                         call_601400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601400, url, valid)

proc call*(call_601401: Call_UpdateFunctionConfiguration_601388;
          FunctionName: string; body: JsonNode): Recallable =
  ## updateFunctionConfiguration
  ## <p>Modify the version-specific settings of a Lambda function.</p> <p>These settings can vary between versions of a function and are locked when you publish a version. You can't modify the configuration of a published version, only the unpublished version.</p> <p>To configure function concurrency, use <a>PutFunctionConcurrency</a>. To grant invoke permissions to an account or AWS service, use <a>AddPermission</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_601402 = newJObject()
  var body_601403 = newJObject()
  add(path_601402, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_601403 = body
  result = call_601401.call(path_601402, nil, nil, nil, body_601403)

var updateFunctionConfiguration* = Call_UpdateFunctionConfiguration_601388(
    name: "updateFunctionConfiguration", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/configuration",
    validator: validate_UpdateFunctionConfiguration_601389, base: "/",
    url: url_UpdateFunctionConfiguration_601390,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionConfiguration_601372 = ref object of OpenApiRestCall_600437
proc url_GetFunctionConfiguration_601374(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetFunctionConfiguration_601373(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the version-specific settings of a Lambda function or version. The output includes only options that can vary between versions of a function. To modify these settings, use <a>UpdateFunctionConfiguration</a>.</p> <p>To get all of a function's details, including function-level settings, use <a>GetFunction</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_601375 = path.getOrDefault("FunctionName")
  valid_601375 = validateParameter(valid_601375, JString, required = true,
                                 default = nil)
  if valid_601375 != nil:
    section.add "FunctionName", valid_601375
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to get details about a published version of the function.
  section = newJObject()
  var valid_601376 = query.getOrDefault("Qualifier")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "Qualifier", valid_601376
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601377 = header.getOrDefault("X-Amz-Date")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Date", valid_601377
  var valid_601378 = header.getOrDefault("X-Amz-Security-Token")
  valid_601378 = validateParameter(valid_601378, JString, required = false,
                                 default = nil)
  if valid_601378 != nil:
    section.add "X-Amz-Security-Token", valid_601378
  var valid_601379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601379 = validateParameter(valid_601379, JString, required = false,
                                 default = nil)
  if valid_601379 != nil:
    section.add "X-Amz-Content-Sha256", valid_601379
  var valid_601380 = header.getOrDefault("X-Amz-Algorithm")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "X-Amz-Algorithm", valid_601380
  var valid_601381 = header.getOrDefault("X-Amz-Signature")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-Signature", valid_601381
  var valid_601382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-SignedHeaders", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Credential")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Credential", valid_601383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601384: Call_GetFunctionConfiguration_601372; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the version-specific settings of a Lambda function or version. The output includes only options that can vary between versions of a function. To modify these settings, use <a>UpdateFunctionConfiguration</a>.</p> <p>To get all of a function's details, including function-level settings, use <a>GetFunction</a>.</p>
  ## 
  let valid = call_601384.validator(path, query, header, formData, body)
  let scheme = call_601384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601384.url(scheme.get, call_601384.host, call_601384.base,
                         call_601384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601384, url, valid)

proc call*(call_601385: Call_GetFunctionConfiguration_601372; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## getFunctionConfiguration
  ## <p>Returns the version-specific settings of a Lambda function or version. The output includes only options that can vary between versions of a function. To modify these settings, use <a>UpdateFunctionConfiguration</a>.</p> <p>To get all of a function's details, including function-level settings, use <a>GetFunction</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to get details about a published version of the function.
  var path_601386 = newJObject()
  var query_601387 = newJObject()
  add(path_601386, "FunctionName", newJString(FunctionName))
  add(query_601387, "Qualifier", newJString(Qualifier))
  result = call_601385.call(path_601386, query_601387, nil, nil, nil)

var getFunctionConfiguration* = Call_GetFunctionConfiguration_601372(
    name: "getFunctionConfiguration", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/configuration",
    validator: validate_GetFunctionConfiguration_601373, base: "/",
    url: url_GetFunctionConfiguration_601374, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLayerVersionByArn_601404 = ref object of OpenApiRestCall_600437
proc url_GetLayerVersionByArn_601406(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetLayerVersionByArn_601405(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   find: JString (required)
  ##   Arn: JString (required)
  ##      : The ARN of the layer version.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `find` field"
  var valid_601420 = query.getOrDefault("find")
  valid_601420 = validateParameter(valid_601420, JString, required = true,
                                 default = newJString("LayerVersion"))
  if valid_601420 != nil:
    section.add "find", valid_601420
  var valid_601421 = query.getOrDefault("Arn")
  valid_601421 = validateParameter(valid_601421, JString, required = true,
                                 default = nil)
  if valid_601421 != nil:
    section.add "Arn", valid_601421
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601422 = header.getOrDefault("X-Amz-Date")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Date", valid_601422
  var valid_601423 = header.getOrDefault("X-Amz-Security-Token")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-Security-Token", valid_601423
  var valid_601424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601424 = validateParameter(valid_601424, JString, required = false,
                                 default = nil)
  if valid_601424 != nil:
    section.add "X-Amz-Content-Sha256", valid_601424
  var valid_601425 = header.getOrDefault("X-Amz-Algorithm")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "X-Amz-Algorithm", valid_601425
  var valid_601426 = header.getOrDefault("X-Amz-Signature")
  valid_601426 = validateParameter(valid_601426, JString, required = false,
                                 default = nil)
  if valid_601426 != nil:
    section.add "X-Amz-Signature", valid_601426
  var valid_601427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601427 = validateParameter(valid_601427, JString, required = false,
                                 default = nil)
  if valid_601427 != nil:
    section.add "X-Amz-SignedHeaders", valid_601427
  var valid_601428 = header.getOrDefault("X-Amz-Credential")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "X-Amz-Credential", valid_601428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601429: Call_GetLayerVersionByArn_601404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ## 
  let valid = call_601429.validator(path, query, header, formData, body)
  let scheme = call_601429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601429.url(scheme.get, call_601429.host, call_601429.base,
                         call_601429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601429, url, valid)

proc call*(call_601430: Call_GetLayerVersionByArn_601404; Arn: string;
          find: string = "LayerVersion"): Recallable =
  ## getLayerVersionByArn
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ##   find: string (required)
  ##   Arn: string (required)
  ##      : The ARN of the layer version.
  var query_601431 = newJObject()
  add(query_601431, "find", newJString(find))
  add(query_601431, "Arn", newJString(Arn))
  result = call_601430.call(nil, query_601431, nil, nil, nil)

var getLayerVersionByArn* = Call_GetLayerVersionByArn_601404(
    name: "getLayerVersionByArn", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers#find=LayerVersion&Arn",
    validator: validate_GetLayerVersionByArn_601405, base: "/",
    url: url_GetLayerVersionByArn_601406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Invoke_601432 = ref object of OpenApiRestCall_600437
proc url_Invoke_601434(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/invocations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_Invoke_601433(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Invokes a Lambda function. You can invoke a function synchronously (and wait for the response), or asynchronously. To invoke a function asynchronously, set <code>InvocationType</code> to <code>Event</code>.</p> <p>For synchronous invocation, details about the function response, including errors, are included in the response body and headers. For either invocation type, you can find more information in the <a href="https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions.html">execution log</a> and <a href="https://docs.aws.amazon.com/lambda/latest/dg/dlq.html">trace</a>. To record function errors for asynchronous invocations, configure your function with a <a href="https://docs.aws.amazon.com/lambda/latest/dg/dlq.html">dead letter queue</a>.</p> <p>When an error occurs, your function may be invoked multiple times. Retry behavior varies by error type, client, event source, and invocation type. For example, if you invoke a function asynchronously and it returns an error, Lambda executes the function up to two more times. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/retries-on-errors.html">Retry Behavior</a>.</p> <p>The status code in the API response doesn't reflect function errors. Error codes are reserved for errors that prevent your function from executing, such as permissions errors, <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limit errors</a>, or issues with your function's code and configuration. For example, Lambda returns <code>TooManyRequestsException</code> if executing the function would cause you to exceed a concurrency limit at either the account level (<code>ConcurrentInvocationLimitExceeded</code>) or function level (<code>ReservedFunctionConcurrentInvocationLimitExceeded</code>).</p> <p>For functions with a long timeout, your client might be disconnected during synchronous invocation while it waits for a response. Configure your HTTP client, SDK, firewall, proxy, or operating system to allow for long connections with timeout or keep-alive settings.</p> <p>This operation requires permission for the <code>lambda:InvokeFunction</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_601435 = path.getOrDefault("FunctionName")
  valid_601435 = validateParameter(valid_601435, JString, required = true,
                                 default = nil)
  if valid_601435 != nil:
    section.add "FunctionName", valid_601435
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to invoke a published version of the function.
  section = newJObject()
  var valid_601436 = query.getOrDefault("Qualifier")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "Qualifier", valid_601436
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Invocation-Type: JString
  ##                        : <p>Choose from the following options.</p> <ul> <li> <p> <code>RequestResponse</code> (default) - Invoke the function synchronously. Keep the connection open until the function returns a response or times out. The API response includes the function response and additional data.</p> </li> <li> <p> <code>Event</code> - Invoke the function asynchronously. Send events that fail multiple times to the function's dead-letter queue (if it's configured). The API response only includes a status code.</p> </li> <li> <p> <code>DryRun</code> - Validate parameter values and verify that the user or role has permission to invoke the function.</p> </li> </ul>
  ##   X-Amz-Client-Context: JString
  ##                       : Up to 3583 bytes of base64-encoded data about the invoking client to pass to the function in the context object.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Log-Type: JString
  ##                 : Set to <code>Tail</code> to include the execution log in the response.
  section = newJObject()
  var valid_601437 = header.getOrDefault("X-Amz-Date")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Date", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-Security-Token")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-Security-Token", valid_601438
  var valid_601439 = header.getOrDefault("X-Amz-Invocation-Type")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = newJString("Event"))
  if valid_601439 != nil:
    section.add "X-Amz-Invocation-Type", valid_601439
  var valid_601440 = header.getOrDefault("X-Amz-Client-Context")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-Client-Context", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Content-Sha256", valid_601441
  var valid_601442 = header.getOrDefault("X-Amz-Algorithm")
  valid_601442 = validateParameter(valid_601442, JString, required = false,
                                 default = nil)
  if valid_601442 != nil:
    section.add "X-Amz-Algorithm", valid_601442
  var valid_601443 = header.getOrDefault("X-Amz-Signature")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-Signature", valid_601443
  var valid_601444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601444 = validateParameter(valid_601444, JString, required = false,
                                 default = nil)
  if valid_601444 != nil:
    section.add "X-Amz-SignedHeaders", valid_601444
  var valid_601445 = header.getOrDefault("X-Amz-Credential")
  valid_601445 = validateParameter(valid_601445, JString, required = false,
                                 default = nil)
  if valid_601445 != nil:
    section.add "X-Amz-Credential", valid_601445
  var valid_601446 = header.getOrDefault("X-Amz-Log-Type")
  valid_601446 = validateParameter(valid_601446, JString, required = false,
                                 default = newJString("None"))
  if valid_601446 != nil:
    section.add "X-Amz-Log-Type", valid_601446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601448: Call_Invoke_601432; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Invokes a Lambda function. You can invoke a function synchronously (and wait for the response), or asynchronously. To invoke a function asynchronously, set <code>InvocationType</code> to <code>Event</code>.</p> <p>For synchronous invocation, details about the function response, including errors, are included in the response body and headers. For either invocation type, you can find more information in the <a href="https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions.html">execution log</a> and <a href="https://docs.aws.amazon.com/lambda/latest/dg/dlq.html">trace</a>. To record function errors for asynchronous invocations, configure your function with a <a href="https://docs.aws.amazon.com/lambda/latest/dg/dlq.html">dead letter queue</a>.</p> <p>When an error occurs, your function may be invoked multiple times. Retry behavior varies by error type, client, event source, and invocation type. For example, if you invoke a function asynchronously and it returns an error, Lambda executes the function up to two more times. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/retries-on-errors.html">Retry Behavior</a>.</p> <p>The status code in the API response doesn't reflect function errors. Error codes are reserved for errors that prevent your function from executing, such as permissions errors, <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limit errors</a>, or issues with your function's code and configuration. For example, Lambda returns <code>TooManyRequestsException</code> if executing the function would cause you to exceed a concurrency limit at either the account level (<code>ConcurrentInvocationLimitExceeded</code>) or function level (<code>ReservedFunctionConcurrentInvocationLimitExceeded</code>).</p> <p>For functions with a long timeout, your client might be disconnected during synchronous invocation while it waits for a response. Configure your HTTP client, SDK, firewall, proxy, or operating system to allow for long connections with timeout or keep-alive settings.</p> <p>This operation requires permission for the <code>lambda:InvokeFunction</code> action.</p>
  ## 
  let valid = call_601448.validator(path, query, header, formData, body)
  let scheme = call_601448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601448.url(scheme.get, call_601448.host, call_601448.base,
                         call_601448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601448, url, valid)

proc call*(call_601449: Call_Invoke_601432; FunctionName: string; body: JsonNode;
          Qualifier: string = ""): Recallable =
  ## invoke
  ## <p>Invokes a Lambda function. You can invoke a function synchronously (and wait for the response), or asynchronously. To invoke a function asynchronously, set <code>InvocationType</code> to <code>Event</code>.</p> <p>For synchronous invocation, details about the function response, including errors, are included in the response body and headers. For either invocation type, you can find more information in the <a href="https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions.html">execution log</a> and <a href="https://docs.aws.amazon.com/lambda/latest/dg/dlq.html">trace</a>. To record function errors for asynchronous invocations, configure your function with a <a href="https://docs.aws.amazon.com/lambda/latest/dg/dlq.html">dead letter queue</a>.</p> <p>When an error occurs, your function may be invoked multiple times. Retry behavior varies by error type, client, event source, and invocation type. For example, if you invoke a function asynchronously and it returns an error, Lambda executes the function up to two more times. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/retries-on-errors.html">Retry Behavior</a>.</p> <p>The status code in the API response doesn't reflect function errors. Error codes are reserved for errors that prevent your function from executing, such as permissions errors, <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limit errors</a>, or issues with your function's code and configuration. For example, Lambda returns <code>TooManyRequestsException</code> if executing the function would cause you to exceed a concurrency limit at either the account level (<code>ConcurrentInvocationLimitExceeded</code>) or function level (<code>ReservedFunctionConcurrentInvocationLimitExceeded</code>).</p> <p>For functions with a long timeout, your client might be disconnected during synchronous invocation while it waits for a response. Configure your HTTP client, SDK, firewall, proxy, or operating system to allow for long connections with timeout or keep-alive settings.</p> <p>This operation requires permission for the <code>lambda:InvokeFunction</code> action.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to invoke a published version of the function.
  ##   body: JObject (required)
  var path_601450 = newJObject()
  var query_601451 = newJObject()
  var body_601452 = newJObject()
  add(path_601450, "FunctionName", newJString(FunctionName))
  add(query_601451, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_601452 = body
  result = call_601449.call(path_601450, query_601451, nil, nil, body_601452)

var invoke* = Call_Invoke_601432(name: "invoke", meth: HttpMethod.HttpPost,
                              host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/invocations",
                              validator: validate_Invoke_601433, base: "/",
                              url: url_Invoke_601434,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvokeAsync_601453 = ref object of OpenApiRestCall_600437
proc url_InvokeAsync_601455(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2014-11-13/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/invoke-async/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_InvokeAsync_601454(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <important> <p>For asynchronous function invocation, use <a>Invoke</a>.</p> </important> <p>Invokes a function asynchronously.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_601456 = path.getOrDefault("FunctionName")
  valid_601456 = validateParameter(valid_601456, JString, required = true,
                                 default = nil)
  if valid_601456 != nil:
    section.add "FunctionName", valid_601456
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601457 = header.getOrDefault("X-Amz-Date")
  valid_601457 = validateParameter(valid_601457, JString, required = false,
                                 default = nil)
  if valid_601457 != nil:
    section.add "X-Amz-Date", valid_601457
  var valid_601458 = header.getOrDefault("X-Amz-Security-Token")
  valid_601458 = validateParameter(valid_601458, JString, required = false,
                                 default = nil)
  if valid_601458 != nil:
    section.add "X-Amz-Security-Token", valid_601458
  var valid_601459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601459 = validateParameter(valid_601459, JString, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "X-Amz-Content-Sha256", valid_601459
  var valid_601460 = header.getOrDefault("X-Amz-Algorithm")
  valid_601460 = validateParameter(valid_601460, JString, required = false,
                                 default = nil)
  if valid_601460 != nil:
    section.add "X-Amz-Algorithm", valid_601460
  var valid_601461 = header.getOrDefault("X-Amz-Signature")
  valid_601461 = validateParameter(valid_601461, JString, required = false,
                                 default = nil)
  if valid_601461 != nil:
    section.add "X-Amz-Signature", valid_601461
  var valid_601462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601462 = validateParameter(valid_601462, JString, required = false,
                                 default = nil)
  if valid_601462 != nil:
    section.add "X-Amz-SignedHeaders", valid_601462
  var valid_601463 = header.getOrDefault("X-Amz-Credential")
  valid_601463 = validateParameter(valid_601463, JString, required = false,
                                 default = nil)
  if valid_601463 != nil:
    section.add "X-Amz-Credential", valid_601463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601465: Call_InvokeAsync_601453; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <important> <p>For asynchronous function invocation, use <a>Invoke</a>.</p> </important> <p>Invokes a function asynchronously.</p>
  ## 
  let valid = call_601465.validator(path, query, header, formData, body)
  let scheme = call_601465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601465.url(scheme.get, call_601465.host, call_601465.base,
                         call_601465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601465, url, valid)

proc call*(call_601466: Call_InvokeAsync_601453; FunctionName: string; body: JsonNode): Recallable =
  ## invokeAsync
  ## <important> <p>For asynchronous function invocation, use <a>Invoke</a>.</p> </important> <p>Invokes a function asynchronously.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_601467 = newJObject()
  var body_601468 = newJObject()
  add(path_601467, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_601468 = body
  result = call_601466.call(path_601467, nil, nil, nil, body_601468)

var invokeAsync* = Call_InvokeAsync_601453(name: "invokeAsync",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com", route: "/2014-11-13/functions/{FunctionName}/invoke-async/",
                                        validator: validate_InvokeAsync_601454,
                                        base: "/", url: url_InvokeAsync_601455,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctions_601469 = ref object of OpenApiRestCall_600437
proc url_ListFunctions_601471(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFunctions_601470(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of Lambda functions, with the version-specific configuration of each.</p> <p>Set <code>FunctionVersion</code> to <code>ALL</code> to include all published versions of each function in addition to the unpublished version. To get more information about a function or version, use <a>GetFunction</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   FunctionVersion: JString
  ##                  : Set to <code>ALL</code> to include entries for all published versions of each function.
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MasterRegion: JString
  ##               : For Lambda@Edge functions, the AWS Region of the master function. For example, <code>us-east-2</code> or <code>ALL</code>. If specified, you must set <code>FunctionVersion</code> to <code>ALL</code>.
  ##   MaxItems: JInt
  ##           : Specify a value between 1 and 50 to limit the number of functions in the response.
  section = newJObject()
  var valid_601472 = query.getOrDefault("FunctionVersion")
  valid_601472 = validateParameter(valid_601472, JString, required = false,
                                 default = newJString("ALL"))
  if valid_601472 != nil:
    section.add "FunctionVersion", valid_601472
  var valid_601473 = query.getOrDefault("Marker")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "Marker", valid_601473
  var valid_601474 = query.getOrDefault("MasterRegion")
  valid_601474 = validateParameter(valid_601474, JString, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "MasterRegion", valid_601474
  var valid_601475 = query.getOrDefault("MaxItems")
  valid_601475 = validateParameter(valid_601475, JInt, required = false, default = nil)
  if valid_601475 != nil:
    section.add "MaxItems", valid_601475
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601476 = header.getOrDefault("X-Amz-Date")
  valid_601476 = validateParameter(valid_601476, JString, required = false,
                                 default = nil)
  if valid_601476 != nil:
    section.add "X-Amz-Date", valid_601476
  var valid_601477 = header.getOrDefault("X-Amz-Security-Token")
  valid_601477 = validateParameter(valid_601477, JString, required = false,
                                 default = nil)
  if valid_601477 != nil:
    section.add "X-Amz-Security-Token", valid_601477
  var valid_601478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601478 = validateParameter(valid_601478, JString, required = false,
                                 default = nil)
  if valid_601478 != nil:
    section.add "X-Amz-Content-Sha256", valid_601478
  var valid_601479 = header.getOrDefault("X-Amz-Algorithm")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "X-Amz-Algorithm", valid_601479
  var valid_601480 = header.getOrDefault("X-Amz-Signature")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-Signature", valid_601480
  var valid_601481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "X-Amz-SignedHeaders", valid_601481
  var valid_601482 = header.getOrDefault("X-Amz-Credential")
  valid_601482 = validateParameter(valid_601482, JString, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "X-Amz-Credential", valid_601482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601483: Call_ListFunctions_601469; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of Lambda functions, with the version-specific configuration of each.</p> <p>Set <code>FunctionVersion</code> to <code>ALL</code> to include all published versions of each function in addition to the unpublished version. To get more information about a function or version, use <a>GetFunction</a>.</p>
  ## 
  let valid = call_601483.validator(path, query, header, formData, body)
  let scheme = call_601483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601483.url(scheme.get, call_601483.host, call_601483.base,
                         call_601483.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601483, url, valid)

proc call*(call_601484: Call_ListFunctions_601469; FunctionVersion: string = "ALL";
          Marker: string = ""; MasterRegion: string = ""; MaxItems: int = 0): Recallable =
  ## listFunctions
  ## <p>Returns a list of Lambda functions, with the version-specific configuration of each.</p> <p>Set <code>FunctionVersion</code> to <code>ALL</code> to include all published versions of each function in addition to the unpublished version. To get more information about a function or version, use <a>GetFunction</a>.</p>
  ##   FunctionVersion: string
  ##                  : Set to <code>ALL</code> to include entries for all published versions of each function.
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MasterRegion: string
  ##               : For Lambda@Edge functions, the AWS Region of the master function. For example, <code>us-east-2</code> or <code>ALL</code>. If specified, you must set <code>FunctionVersion</code> to <code>ALL</code>.
  ##   MaxItems: int
  ##           : Specify a value between 1 and 50 to limit the number of functions in the response.
  var query_601485 = newJObject()
  add(query_601485, "FunctionVersion", newJString(FunctionVersion))
  add(query_601485, "Marker", newJString(Marker))
  add(query_601485, "MasterRegion", newJString(MasterRegion))
  add(query_601485, "MaxItems", newJInt(MaxItems))
  result = call_601484.call(nil, query_601485, nil, nil, nil)

var listFunctions* = Call_ListFunctions_601469(name: "listFunctions",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/", validator: validate_ListFunctions_601470,
    base: "/", url: url_ListFunctions_601471, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishLayerVersion_601504 = ref object of OpenApiRestCall_600437
proc url_PublishLayerVersion_601506(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LayerName" in path, "`LayerName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-10-31/layers/"),
               (kind: VariableSegment, value: "LayerName"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PublishLayerVersion_601505(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a> from a ZIP archive. Each time you call <code>PublishLayerVersion</code> with the same version name, a new version is created.</p> <p>Add layers to your function with <a>CreateFunction</a> or <a>UpdateFunctionConfiguration</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `LayerName` field"
  var valid_601507 = path.getOrDefault("LayerName")
  valid_601507 = validateParameter(valid_601507, JString, required = true,
                                 default = nil)
  if valid_601507 != nil:
    section.add "LayerName", valid_601507
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601508 = header.getOrDefault("X-Amz-Date")
  valid_601508 = validateParameter(valid_601508, JString, required = false,
                                 default = nil)
  if valid_601508 != nil:
    section.add "X-Amz-Date", valid_601508
  var valid_601509 = header.getOrDefault("X-Amz-Security-Token")
  valid_601509 = validateParameter(valid_601509, JString, required = false,
                                 default = nil)
  if valid_601509 != nil:
    section.add "X-Amz-Security-Token", valid_601509
  var valid_601510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601510 = validateParameter(valid_601510, JString, required = false,
                                 default = nil)
  if valid_601510 != nil:
    section.add "X-Amz-Content-Sha256", valid_601510
  var valid_601511 = header.getOrDefault("X-Amz-Algorithm")
  valid_601511 = validateParameter(valid_601511, JString, required = false,
                                 default = nil)
  if valid_601511 != nil:
    section.add "X-Amz-Algorithm", valid_601511
  var valid_601512 = header.getOrDefault("X-Amz-Signature")
  valid_601512 = validateParameter(valid_601512, JString, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "X-Amz-Signature", valid_601512
  var valid_601513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601513 = validateParameter(valid_601513, JString, required = false,
                                 default = nil)
  if valid_601513 != nil:
    section.add "X-Amz-SignedHeaders", valid_601513
  var valid_601514 = header.getOrDefault("X-Amz-Credential")
  valid_601514 = validateParameter(valid_601514, JString, required = false,
                                 default = nil)
  if valid_601514 != nil:
    section.add "X-Amz-Credential", valid_601514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601516: Call_PublishLayerVersion_601504; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a> from a ZIP archive. Each time you call <code>PublishLayerVersion</code> with the same version name, a new version is created.</p> <p>Add layers to your function with <a>CreateFunction</a> or <a>UpdateFunctionConfiguration</a>.</p>
  ## 
  let valid = call_601516.validator(path, query, header, formData, body)
  let scheme = call_601516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601516.url(scheme.get, call_601516.host, call_601516.base,
                         call_601516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601516, url, valid)

proc call*(call_601517: Call_PublishLayerVersion_601504; LayerName: string;
          body: JsonNode): Recallable =
  ## publishLayerVersion
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a> from a ZIP archive. Each time you call <code>PublishLayerVersion</code> with the same version name, a new version is created.</p> <p>Add layers to your function with <a>CreateFunction</a> or <a>UpdateFunctionConfiguration</a>.</p>
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   body: JObject (required)
  var path_601518 = newJObject()
  var body_601519 = newJObject()
  add(path_601518, "LayerName", newJString(LayerName))
  if body != nil:
    body_601519 = body
  result = call_601517.call(path_601518, nil, nil, nil, body_601519)

var publishLayerVersion* = Call_PublishLayerVersion_601504(
    name: "publishLayerVersion", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions",
    validator: validate_PublishLayerVersion_601505, base: "/",
    url: url_PublishLayerVersion_601506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLayerVersions_601486 = ref object of OpenApiRestCall_600437
proc url_ListLayerVersions_601488(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LayerName" in path, "`LayerName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-10-31/layers/"),
               (kind: VariableSegment, value: "LayerName"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListLayerVersions_601487(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Lists the versions of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Versions that have been deleted aren't listed. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only versions that indicate that they're compatible with that runtime.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `LayerName` field"
  var valid_601489 = path.getOrDefault("LayerName")
  valid_601489 = validateParameter(valid_601489, JString, required = true,
                                 default = nil)
  if valid_601489 != nil:
    section.add "LayerName", valid_601489
  result.add "path", section
  ## parameters in `query` object:
  ##   CompatibleRuntime: JString
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   Marker: JString
  ##         : A pagination token returned by a previous call.
  ##   MaxItems: JInt
  ##           : The maximum number of versions to return.
  section = newJObject()
  var valid_601490 = query.getOrDefault("CompatibleRuntime")
  valid_601490 = validateParameter(valid_601490, JString, required = false,
                                 default = newJString("nodejs"))
  if valid_601490 != nil:
    section.add "CompatibleRuntime", valid_601490
  var valid_601491 = query.getOrDefault("Marker")
  valid_601491 = validateParameter(valid_601491, JString, required = false,
                                 default = nil)
  if valid_601491 != nil:
    section.add "Marker", valid_601491
  var valid_601492 = query.getOrDefault("MaxItems")
  valid_601492 = validateParameter(valid_601492, JInt, required = false, default = nil)
  if valid_601492 != nil:
    section.add "MaxItems", valid_601492
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601493 = header.getOrDefault("X-Amz-Date")
  valid_601493 = validateParameter(valid_601493, JString, required = false,
                                 default = nil)
  if valid_601493 != nil:
    section.add "X-Amz-Date", valid_601493
  var valid_601494 = header.getOrDefault("X-Amz-Security-Token")
  valid_601494 = validateParameter(valid_601494, JString, required = false,
                                 default = nil)
  if valid_601494 != nil:
    section.add "X-Amz-Security-Token", valid_601494
  var valid_601495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601495 = validateParameter(valid_601495, JString, required = false,
                                 default = nil)
  if valid_601495 != nil:
    section.add "X-Amz-Content-Sha256", valid_601495
  var valid_601496 = header.getOrDefault("X-Amz-Algorithm")
  valid_601496 = validateParameter(valid_601496, JString, required = false,
                                 default = nil)
  if valid_601496 != nil:
    section.add "X-Amz-Algorithm", valid_601496
  var valid_601497 = header.getOrDefault("X-Amz-Signature")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "X-Amz-Signature", valid_601497
  var valid_601498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "X-Amz-SignedHeaders", valid_601498
  var valid_601499 = header.getOrDefault("X-Amz-Credential")
  valid_601499 = validateParameter(valid_601499, JString, required = false,
                                 default = nil)
  if valid_601499 != nil:
    section.add "X-Amz-Credential", valid_601499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601500: Call_ListLayerVersions_601486; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Versions that have been deleted aren't listed. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only versions that indicate that they're compatible with that runtime.
  ## 
  let valid = call_601500.validator(path, query, header, formData, body)
  let scheme = call_601500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601500.url(scheme.get, call_601500.host, call_601500.base,
                         call_601500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601500, url, valid)

proc call*(call_601501: Call_ListLayerVersions_601486; LayerName: string;
          CompatibleRuntime: string = "nodejs"; Marker: string = ""; MaxItems: int = 0): Recallable =
  ## listLayerVersions
  ## Lists the versions of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Versions that have been deleted aren't listed. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only versions that indicate that they're compatible with that runtime.
  ##   CompatibleRuntime: string
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   Marker: string
  ##         : A pagination token returned by a previous call.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   MaxItems: int
  ##           : The maximum number of versions to return.
  var path_601502 = newJObject()
  var query_601503 = newJObject()
  add(query_601503, "CompatibleRuntime", newJString(CompatibleRuntime))
  add(query_601503, "Marker", newJString(Marker))
  add(path_601502, "LayerName", newJString(LayerName))
  add(query_601503, "MaxItems", newJInt(MaxItems))
  result = call_601501.call(path_601502, query_601503, nil, nil, nil)

var listLayerVersions* = Call_ListLayerVersions_601486(name: "listLayerVersions",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions",
    validator: validate_ListLayerVersions_601487, base: "/",
    url: url_ListLayerVersions_601488, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLayers_601520 = ref object of OpenApiRestCall_600437
proc url_ListLayers_601522(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLayers_601521(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layers</a> and shows information about the latest version of each. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only layers that indicate that they're compatible with that runtime.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   CompatibleRuntime: JString
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   Marker: JString
  ##         : A pagination token returned by a previous call.
  ##   MaxItems: JInt
  ##           : The maximum number of layers to return.
  section = newJObject()
  var valid_601523 = query.getOrDefault("CompatibleRuntime")
  valid_601523 = validateParameter(valid_601523, JString, required = false,
                                 default = newJString("nodejs"))
  if valid_601523 != nil:
    section.add "CompatibleRuntime", valid_601523
  var valid_601524 = query.getOrDefault("Marker")
  valid_601524 = validateParameter(valid_601524, JString, required = false,
                                 default = nil)
  if valid_601524 != nil:
    section.add "Marker", valid_601524
  var valid_601525 = query.getOrDefault("MaxItems")
  valid_601525 = validateParameter(valid_601525, JInt, required = false, default = nil)
  if valid_601525 != nil:
    section.add "MaxItems", valid_601525
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601526 = header.getOrDefault("X-Amz-Date")
  valid_601526 = validateParameter(valid_601526, JString, required = false,
                                 default = nil)
  if valid_601526 != nil:
    section.add "X-Amz-Date", valid_601526
  var valid_601527 = header.getOrDefault("X-Amz-Security-Token")
  valid_601527 = validateParameter(valid_601527, JString, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "X-Amz-Security-Token", valid_601527
  var valid_601528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601528 = validateParameter(valid_601528, JString, required = false,
                                 default = nil)
  if valid_601528 != nil:
    section.add "X-Amz-Content-Sha256", valid_601528
  var valid_601529 = header.getOrDefault("X-Amz-Algorithm")
  valid_601529 = validateParameter(valid_601529, JString, required = false,
                                 default = nil)
  if valid_601529 != nil:
    section.add "X-Amz-Algorithm", valid_601529
  var valid_601530 = header.getOrDefault("X-Amz-Signature")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "X-Amz-Signature", valid_601530
  var valid_601531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "X-Amz-SignedHeaders", valid_601531
  var valid_601532 = header.getOrDefault("X-Amz-Credential")
  valid_601532 = validateParameter(valid_601532, JString, required = false,
                                 default = nil)
  if valid_601532 != nil:
    section.add "X-Amz-Credential", valid_601532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601533: Call_ListLayers_601520; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layers</a> and shows information about the latest version of each. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only layers that indicate that they're compatible with that runtime.
  ## 
  let valid = call_601533.validator(path, query, header, formData, body)
  let scheme = call_601533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601533.url(scheme.get, call_601533.host, call_601533.base,
                         call_601533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601533, url, valid)

proc call*(call_601534: Call_ListLayers_601520;
          CompatibleRuntime: string = "nodejs"; Marker: string = ""; MaxItems: int = 0): Recallable =
  ## listLayers
  ## Lists <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layers</a> and shows information about the latest version of each. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only layers that indicate that they're compatible with that runtime.
  ##   CompatibleRuntime: string
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   Marker: string
  ##         : A pagination token returned by a previous call.
  ##   MaxItems: int
  ##           : The maximum number of layers to return.
  var query_601535 = newJObject()
  add(query_601535, "CompatibleRuntime", newJString(CompatibleRuntime))
  add(query_601535, "Marker", newJString(Marker))
  add(query_601535, "MaxItems", newJInt(MaxItems))
  result = call_601534.call(nil, query_601535, nil, nil, nil)

var listLayers* = Call_ListLayers_601520(name: "listLayers",
                                      meth: HttpMethod.HttpGet,
                                      host: "lambda.amazonaws.com",
                                      route: "/2018-10-31/layers",
                                      validator: validate_ListLayers_601521,
                                      base: "/", url: url_ListLayers_601522,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601550 = ref object of OpenApiRestCall_600437
proc url_TagResource_601552(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ARN" in path, "`ARN` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-31/tags/"),
               (kind: VariableSegment, value: "ARN")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_TagResource_601551(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> to a function.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ARN: JString (required)
  ##      : The function's Amazon Resource Name (ARN).
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ARN` field"
  var valid_601553 = path.getOrDefault("ARN")
  valid_601553 = validateParameter(valid_601553, JString, required = true,
                                 default = nil)
  if valid_601553 != nil:
    section.add "ARN", valid_601553
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601554 = header.getOrDefault("X-Amz-Date")
  valid_601554 = validateParameter(valid_601554, JString, required = false,
                                 default = nil)
  if valid_601554 != nil:
    section.add "X-Amz-Date", valid_601554
  var valid_601555 = header.getOrDefault("X-Amz-Security-Token")
  valid_601555 = validateParameter(valid_601555, JString, required = false,
                                 default = nil)
  if valid_601555 != nil:
    section.add "X-Amz-Security-Token", valid_601555
  var valid_601556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601556 = validateParameter(valid_601556, JString, required = false,
                                 default = nil)
  if valid_601556 != nil:
    section.add "X-Amz-Content-Sha256", valid_601556
  var valid_601557 = header.getOrDefault("X-Amz-Algorithm")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "X-Amz-Algorithm", valid_601557
  var valid_601558 = header.getOrDefault("X-Amz-Signature")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "X-Amz-Signature", valid_601558
  var valid_601559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601559 = validateParameter(valid_601559, JString, required = false,
                                 default = nil)
  if valid_601559 != nil:
    section.add "X-Amz-SignedHeaders", valid_601559
  var valid_601560 = header.getOrDefault("X-Amz-Credential")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "X-Amz-Credential", valid_601560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601562: Call_TagResource_601550; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> to a function.
  ## 
  let valid = call_601562.validator(path, query, header, formData, body)
  let scheme = call_601562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601562.url(scheme.get, call_601562.host, call_601562.base,
                         call_601562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601562, url, valid)

proc call*(call_601563: Call_TagResource_601550; ARN: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> to a function.
  ##   ARN: string (required)
  ##      : The function's Amazon Resource Name (ARN).
  ##   body: JObject (required)
  var path_601564 = newJObject()
  var body_601565 = newJObject()
  add(path_601564, "ARN", newJString(ARN))
  if body != nil:
    body_601565 = body
  result = call_601563.call(path_601564, nil, nil, nil, body_601565)

var tagResource* = Call_TagResource_601550(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com",
                                        route: "/2017-03-31/tags/{ARN}",
                                        validator: validate_TagResource_601551,
                                        base: "/", url: url_TagResource_601552,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_601536 = ref object of OpenApiRestCall_600437
proc url_ListTags_601538(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ARN" in path, "`ARN` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-31/tags/"),
               (kind: VariableSegment, value: "ARN")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListTags_601537(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a>. You can also view tags with <a>GetFunction</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ARN: JString (required)
  ##      : The function's Amazon Resource Name (ARN).
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ARN` field"
  var valid_601539 = path.getOrDefault("ARN")
  valid_601539 = validateParameter(valid_601539, JString, required = true,
                                 default = nil)
  if valid_601539 != nil:
    section.add "ARN", valid_601539
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601540 = header.getOrDefault("X-Amz-Date")
  valid_601540 = validateParameter(valid_601540, JString, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "X-Amz-Date", valid_601540
  var valid_601541 = header.getOrDefault("X-Amz-Security-Token")
  valid_601541 = validateParameter(valid_601541, JString, required = false,
                                 default = nil)
  if valid_601541 != nil:
    section.add "X-Amz-Security-Token", valid_601541
  var valid_601542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-Content-Sha256", valid_601542
  var valid_601543 = header.getOrDefault("X-Amz-Algorithm")
  valid_601543 = validateParameter(valid_601543, JString, required = false,
                                 default = nil)
  if valid_601543 != nil:
    section.add "X-Amz-Algorithm", valid_601543
  var valid_601544 = header.getOrDefault("X-Amz-Signature")
  valid_601544 = validateParameter(valid_601544, JString, required = false,
                                 default = nil)
  if valid_601544 != nil:
    section.add "X-Amz-Signature", valid_601544
  var valid_601545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601545 = validateParameter(valid_601545, JString, required = false,
                                 default = nil)
  if valid_601545 != nil:
    section.add "X-Amz-SignedHeaders", valid_601545
  var valid_601546 = header.getOrDefault("X-Amz-Credential")
  valid_601546 = validateParameter(valid_601546, JString, required = false,
                                 default = nil)
  if valid_601546 != nil:
    section.add "X-Amz-Credential", valid_601546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601547: Call_ListTags_601536; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a>. You can also view tags with <a>GetFunction</a>.
  ## 
  let valid = call_601547.validator(path, query, header, formData, body)
  let scheme = call_601547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601547.url(scheme.get, call_601547.host, call_601547.base,
                         call_601547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601547, url, valid)

proc call*(call_601548: Call_ListTags_601536; ARN: string): Recallable =
  ## listTags
  ## Returns a function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a>. You can also view tags with <a>GetFunction</a>.
  ##   ARN: string (required)
  ##      : The function's Amazon Resource Name (ARN).
  var path_601549 = newJObject()
  add(path_601549, "ARN", newJString(ARN))
  result = call_601548.call(path_601549, nil, nil, nil, nil)

var listTags* = Call_ListTags_601536(name: "listTags", meth: HttpMethod.HttpGet,
                                  host: "lambda.amazonaws.com",
                                  route: "/2017-03-31/tags/{ARN}",
                                  validator: validate_ListTags_601537, base: "/",
                                  url: url_ListTags_601538,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishVersion_601583 = ref object of OpenApiRestCall_600437
proc url_PublishVersion_601585(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PublishVersion_601584(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">version</a> from the current code and configuration of a function. Use versions to create a snapshot of your function code and configuration that doesn't change.</p> <p>AWS Lambda doesn't publish a version if the function's configuration and code haven't changed since the last version. Use <a>UpdateFunctionCode</a> or <a>UpdateFunctionConfiguration</a> to update the function before publishing a version.</p> <p>Clients can invoke versions directly or with an alias. To create an alias, use <a>CreateAlias</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_601586 = path.getOrDefault("FunctionName")
  valid_601586 = validateParameter(valid_601586, JString, required = true,
                                 default = nil)
  if valid_601586 != nil:
    section.add "FunctionName", valid_601586
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601587 = header.getOrDefault("X-Amz-Date")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "X-Amz-Date", valid_601587
  var valid_601588 = header.getOrDefault("X-Amz-Security-Token")
  valid_601588 = validateParameter(valid_601588, JString, required = false,
                                 default = nil)
  if valid_601588 != nil:
    section.add "X-Amz-Security-Token", valid_601588
  var valid_601589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601589 = validateParameter(valid_601589, JString, required = false,
                                 default = nil)
  if valid_601589 != nil:
    section.add "X-Amz-Content-Sha256", valid_601589
  var valid_601590 = header.getOrDefault("X-Amz-Algorithm")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "X-Amz-Algorithm", valid_601590
  var valid_601591 = header.getOrDefault("X-Amz-Signature")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "X-Amz-Signature", valid_601591
  var valid_601592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "X-Amz-SignedHeaders", valid_601592
  var valid_601593 = header.getOrDefault("X-Amz-Credential")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "X-Amz-Credential", valid_601593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601595: Call_PublishVersion_601583; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">version</a> from the current code and configuration of a function. Use versions to create a snapshot of your function code and configuration that doesn't change.</p> <p>AWS Lambda doesn't publish a version if the function's configuration and code haven't changed since the last version. Use <a>UpdateFunctionCode</a> or <a>UpdateFunctionConfiguration</a> to update the function before publishing a version.</p> <p>Clients can invoke versions directly or with an alias. To create an alias, use <a>CreateAlias</a>.</p>
  ## 
  let valid = call_601595.validator(path, query, header, formData, body)
  let scheme = call_601595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601595.url(scheme.get, call_601595.host, call_601595.base,
                         call_601595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601595, url, valid)

proc call*(call_601596: Call_PublishVersion_601583; FunctionName: string;
          body: JsonNode): Recallable =
  ## publishVersion
  ## <p>Creates a <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">version</a> from the current code and configuration of a function. Use versions to create a snapshot of your function code and configuration that doesn't change.</p> <p>AWS Lambda doesn't publish a version if the function's configuration and code haven't changed since the last version. Use <a>UpdateFunctionCode</a> or <a>UpdateFunctionConfiguration</a> to update the function before publishing a version.</p> <p>Clients can invoke versions directly or with an alias. To create an alias, use <a>CreateAlias</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_601597 = newJObject()
  var body_601598 = newJObject()
  add(path_601597, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_601598 = body
  result = call_601596.call(path_601597, nil, nil, nil, body_601598)

var publishVersion* = Call_PublishVersion_601583(name: "publishVersion",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/versions",
    validator: validate_PublishVersion_601584, base: "/", url: url_PublishVersion_601585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVersionsByFunction_601566 = ref object of OpenApiRestCall_600437
proc url_ListVersionsByFunction_601568(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListVersionsByFunction_601567(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">versions</a>, with the version-specific configuration of each. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_601569 = path.getOrDefault("FunctionName")
  valid_601569 = validateParameter(valid_601569, JString, required = true,
                                 default = nil)
  if valid_601569 != nil:
    section.add "FunctionName", valid_601569
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : Limit the number of versions that are returned.
  section = newJObject()
  var valid_601570 = query.getOrDefault("Marker")
  valid_601570 = validateParameter(valid_601570, JString, required = false,
                                 default = nil)
  if valid_601570 != nil:
    section.add "Marker", valid_601570
  var valid_601571 = query.getOrDefault("MaxItems")
  valid_601571 = validateParameter(valid_601571, JInt, required = false, default = nil)
  if valid_601571 != nil:
    section.add "MaxItems", valid_601571
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601572 = header.getOrDefault("X-Amz-Date")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "X-Amz-Date", valid_601572
  var valid_601573 = header.getOrDefault("X-Amz-Security-Token")
  valid_601573 = validateParameter(valid_601573, JString, required = false,
                                 default = nil)
  if valid_601573 != nil:
    section.add "X-Amz-Security-Token", valid_601573
  var valid_601574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601574 = validateParameter(valid_601574, JString, required = false,
                                 default = nil)
  if valid_601574 != nil:
    section.add "X-Amz-Content-Sha256", valid_601574
  var valid_601575 = header.getOrDefault("X-Amz-Algorithm")
  valid_601575 = validateParameter(valid_601575, JString, required = false,
                                 default = nil)
  if valid_601575 != nil:
    section.add "X-Amz-Algorithm", valid_601575
  var valid_601576 = header.getOrDefault("X-Amz-Signature")
  valid_601576 = validateParameter(valid_601576, JString, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "X-Amz-Signature", valid_601576
  var valid_601577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601577 = validateParameter(valid_601577, JString, required = false,
                                 default = nil)
  if valid_601577 != nil:
    section.add "X-Amz-SignedHeaders", valid_601577
  var valid_601578 = header.getOrDefault("X-Amz-Credential")
  valid_601578 = validateParameter(valid_601578, JString, required = false,
                                 default = nil)
  if valid_601578 != nil:
    section.add "X-Amz-Credential", valid_601578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601579: Call_ListVersionsByFunction_601566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">versions</a>, with the version-specific configuration of each. 
  ## 
  let valid = call_601579.validator(path, query, header, formData, body)
  let scheme = call_601579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601579.url(scheme.get, call_601579.host, call_601579.base,
                         call_601579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601579, url, valid)

proc call*(call_601580: Call_ListVersionsByFunction_601566; FunctionName: string;
          Marker: string = ""; MaxItems: int = 0): Recallable =
  ## listVersionsByFunction
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">versions</a>, with the version-specific configuration of each. 
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: int
  ##           : Limit the number of versions that are returned.
  var path_601581 = newJObject()
  var query_601582 = newJObject()
  add(path_601581, "FunctionName", newJString(FunctionName))
  add(query_601582, "Marker", newJString(Marker))
  add(query_601582, "MaxItems", newJInt(MaxItems))
  result = call_601580.call(path_601581, query_601582, nil, nil, nil)

var listVersionsByFunction* = Call_ListVersionsByFunction_601566(
    name: "listVersionsByFunction", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/versions",
    validator: validate_ListVersionsByFunction_601567, base: "/",
    url: url_ListVersionsByFunction_601568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveLayerVersionPermission_601599 = ref object of OpenApiRestCall_600437
proc url_RemoveLayerVersionPermission_601601(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LayerName" in path, "`LayerName` is a required path parameter"
  assert "VersionNumber" in path, "`VersionNumber` is a required path parameter"
  assert "StatementId" in path, "`StatementId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-10-31/layers/"),
               (kind: VariableSegment, value: "LayerName"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "VersionNumber"),
               (kind: ConstantSegment, value: "/policy/"),
               (kind: VariableSegment, value: "StatementId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_RemoveLayerVersionPermission_601600(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a statement from the permissions policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   VersionNumber: JInt (required)
  ##                : The version number.
  ##   StatementId: JString (required)
  ##              : The identifier that was specified when the statement was added.
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `VersionNumber` field"
  var valid_601602 = path.getOrDefault("VersionNumber")
  valid_601602 = validateParameter(valid_601602, JInt, required = true, default = nil)
  if valid_601602 != nil:
    section.add "VersionNumber", valid_601602
  var valid_601603 = path.getOrDefault("StatementId")
  valid_601603 = validateParameter(valid_601603, JString, required = true,
                                 default = nil)
  if valid_601603 != nil:
    section.add "StatementId", valid_601603
  var valid_601604 = path.getOrDefault("LayerName")
  valid_601604 = validateParameter(valid_601604, JString, required = true,
                                 default = nil)
  if valid_601604 != nil:
    section.add "LayerName", valid_601604
  result.add "path", section
  ## parameters in `query` object:
  ##   RevisionId: JString
  ##             : Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  section = newJObject()
  var valid_601605 = query.getOrDefault("RevisionId")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "RevisionId", valid_601605
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601606 = header.getOrDefault("X-Amz-Date")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "X-Amz-Date", valid_601606
  var valid_601607 = header.getOrDefault("X-Amz-Security-Token")
  valid_601607 = validateParameter(valid_601607, JString, required = false,
                                 default = nil)
  if valid_601607 != nil:
    section.add "X-Amz-Security-Token", valid_601607
  var valid_601608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "X-Amz-Content-Sha256", valid_601608
  var valid_601609 = header.getOrDefault("X-Amz-Algorithm")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "X-Amz-Algorithm", valid_601609
  var valid_601610 = header.getOrDefault("X-Amz-Signature")
  valid_601610 = validateParameter(valid_601610, JString, required = false,
                                 default = nil)
  if valid_601610 != nil:
    section.add "X-Amz-Signature", valid_601610
  var valid_601611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601611 = validateParameter(valid_601611, JString, required = false,
                                 default = nil)
  if valid_601611 != nil:
    section.add "X-Amz-SignedHeaders", valid_601611
  var valid_601612 = header.getOrDefault("X-Amz-Credential")
  valid_601612 = validateParameter(valid_601612, JString, required = false,
                                 default = nil)
  if valid_601612 != nil:
    section.add "X-Amz-Credential", valid_601612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601613: Call_RemoveLayerVersionPermission_601599; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from the permissions policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ## 
  let valid = call_601613.validator(path, query, header, formData, body)
  let scheme = call_601613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601613.url(scheme.get, call_601613.host, call_601613.base,
                         call_601613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601613, url, valid)

proc call*(call_601614: Call_RemoveLayerVersionPermission_601599;
          VersionNumber: int; StatementId: string; LayerName: string;
          RevisionId: string = ""): Recallable =
  ## removeLayerVersionPermission
  ## Removes a statement from the permissions policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ##   RevisionId: string
  ##             : Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   StatementId: string (required)
  ##              : The identifier that was specified when the statement was added.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_601615 = newJObject()
  var query_601616 = newJObject()
  add(query_601616, "RevisionId", newJString(RevisionId))
  add(path_601615, "VersionNumber", newJInt(VersionNumber))
  add(path_601615, "StatementId", newJString(StatementId))
  add(path_601615, "LayerName", newJString(LayerName))
  result = call_601614.call(path_601615, query_601616, nil, nil, nil)

var removeLayerVersionPermission* = Call_RemoveLayerVersionPermission_601599(
    name: "removeLayerVersionPermission", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com", route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy/{StatementId}",
    validator: validate_RemoveLayerVersionPermission_601600, base: "/",
    url: url_RemoveLayerVersionPermission_601601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemovePermission_601617 = ref object of OpenApiRestCall_600437
proc url_RemovePermission_601619(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  assert "StatementId" in path, "`StatementId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/policy/"),
               (kind: VariableSegment, value: "StatementId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_RemovePermission_601618(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Revokes function-use permission from an AWS service or another account. You can get the ID of the statement from the output of <a>GetPolicy</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   StatementId: JString (required)
  ##              : Statement ID of the permission to remove.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_601620 = path.getOrDefault("FunctionName")
  valid_601620 = validateParameter(valid_601620, JString, required = true,
                                 default = nil)
  if valid_601620 != nil:
    section.add "FunctionName", valid_601620
  var valid_601621 = path.getOrDefault("StatementId")
  valid_601621 = validateParameter(valid_601621, JString, required = true,
                                 default = nil)
  if valid_601621 != nil:
    section.add "StatementId", valid_601621
  result.add "path", section
  ## parameters in `query` object:
  ##   RevisionId: JString
  ##             : Only update the policy if the revision ID matches the ID that's specified. Use this option to avoid modifying a policy that has changed since you last read it.
  ##   Qualifier: JString
  ##            : Specify a version or alias to remove permissions from a published version of the function.
  section = newJObject()
  var valid_601622 = query.getOrDefault("RevisionId")
  valid_601622 = validateParameter(valid_601622, JString, required = false,
                                 default = nil)
  if valid_601622 != nil:
    section.add "RevisionId", valid_601622
  var valid_601623 = query.getOrDefault("Qualifier")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "Qualifier", valid_601623
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601624 = header.getOrDefault("X-Amz-Date")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "X-Amz-Date", valid_601624
  var valid_601625 = header.getOrDefault("X-Amz-Security-Token")
  valid_601625 = validateParameter(valid_601625, JString, required = false,
                                 default = nil)
  if valid_601625 != nil:
    section.add "X-Amz-Security-Token", valid_601625
  var valid_601626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601626 = validateParameter(valid_601626, JString, required = false,
                                 default = nil)
  if valid_601626 != nil:
    section.add "X-Amz-Content-Sha256", valid_601626
  var valid_601627 = header.getOrDefault("X-Amz-Algorithm")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "X-Amz-Algorithm", valid_601627
  var valid_601628 = header.getOrDefault("X-Amz-Signature")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "X-Amz-Signature", valid_601628
  var valid_601629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601629 = validateParameter(valid_601629, JString, required = false,
                                 default = nil)
  if valid_601629 != nil:
    section.add "X-Amz-SignedHeaders", valid_601629
  var valid_601630 = header.getOrDefault("X-Amz-Credential")
  valid_601630 = validateParameter(valid_601630, JString, required = false,
                                 default = nil)
  if valid_601630 != nil:
    section.add "X-Amz-Credential", valid_601630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601631: Call_RemovePermission_601617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes function-use permission from an AWS service or another account. You can get the ID of the statement from the output of <a>GetPolicy</a>.
  ## 
  let valid = call_601631.validator(path, query, header, formData, body)
  let scheme = call_601631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601631.url(scheme.get, call_601631.host, call_601631.base,
                         call_601631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601631, url, valid)

proc call*(call_601632: Call_RemovePermission_601617; FunctionName: string;
          StatementId: string; RevisionId: string = ""; Qualifier: string = ""): Recallable =
  ## removePermission
  ## Revokes function-use permission from an AWS service or another account. You can get the ID of the statement from the output of <a>GetPolicy</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   RevisionId: string
  ##             : Only update the policy if the revision ID matches the ID that's specified. Use this option to avoid modifying a policy that has changed since you last read it.
  ##   StatementId: string (required)
  ##              : Statement ID of the permission to remove.
  ##   Qualifier: string
  ##            : Specify a version or alias to remove permissions from a published version of the function.
  var path_601633 = newJObject()
  var query_601634 = newJObject()
  add(path_601633, "FunctionName", newJString(FunctionName))
  add(query_601634, "RevisionId", newJString(RevisionId))
  add(path_601633, "StatementId", newJString(StatementId))
  add(query_601634, "Qualifier", newJString(Qualifier))
  result = call_601632.call(path_601633, query_601634, nil, nil, nil)

var removePermission* = Call_RemovePermission_601617(name: "removePermission",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/policy/{StatementId}",
    validator: validate_RemovePermission_601618, base: "/",
    url: url_RemovePermission_601619, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601635 = ref object of OpenApiRestCall_600437
proc url_UntagResource_601637(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ARN" in path, "`ARN` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-31/tags/"),
               (kind: VariableSegment, value: "ARN"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UntagResource_601636(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> from a function.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ARN: JString (required)
  ##      : The function's Amazon Resource Name (ARN).
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ARN` field"
  var valid_601638 = path.getOrDefault("ARN")
  valid_601638 = validateParameter(valid_601638, JString, required = true,
                                 default = nil)
  if valid_601638 != nil:
    section.add "ARN", valid_601638
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A list of tag keys to remove from the function.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_601639 = query.getOrDefault("tagKeys")
  valid_601639 = validateParameter(valid_601639, JArray, required = true, default = nil)
  if valid_601639 != nil:
    section.add "tagKeys", valid_601639
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601640 = header.getOrDefault("X-Amz-Date")
  valid_601640 = validateParameter(valid_601640, JString, required = false,
                                 default = nil)
  if valid_601640 != nil:
    section.add "X-Amz-Date", valid_601640
  var valid_601641 = header.getOrDefault("X-Amz-Security-Token")
  valid_601641 = validateParameter(valid_601641, JString, required = false,
                                 default = nil)
  if valid_601641 != nil:
    section.add "X-Amz-Security-Token", valid_601641
  var valid_601642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601642 = validateParameter(valid_601642, JString, required = false,
                                 default = nil)
  if valid_601642 != nil:
    section.add "X-Amz-Content-Sha256", valid_601642
  var valid_601643 = header.getOrDefault("X-Amz-Algorithm")
  valid_601643 = validateParameter(valid_601643, JString, required = false,
                                 default = nil)
  if valid_601643 != nil:
    section.add "X-Amz-Algorithm", valid_601643
  var valid_601644 = header.getOrDefault("X-Amz-Signature")
  valid_601644 = validateParameter(valid_601644, JString, required = false,
                                 default = nil)
  if valid_601644 != nil:
    section.add "X-Amz-Signature", valid_601644
  var valid_601645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601645 = validateParameter(valid_601645, JString, required = false,
                                 default = nil)
  if valid_601645 != nil:
    section.add "X-Amz-SignedHeaders", valid_601645
  var valid_601646 = header.getOrDefault("X-Amz-Credential")
  valid_601646 = validateParameter(valid_601646, JString, required = false,
                                 default = nil)
  if valid_601646 != nil:
    section.add "X-Amz-Credential", valid_601646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601647: Call_UntagResource_601635; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> from a function.
  ## 
  let valid = call_601647.validator(path, query, header, formData, body)
  let scheme = call_601647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601647.url(scheme.get, call_601647.host, call_601647.base,
                         call_601647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601647, url, valid)

proc call*(call_601648: Call_UntagResource_601635; ARN: string; tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> from a function.
  ##   ARN: string (required)
  ##      : The function's Amazon Resource Name (ARN).
  ##   tagKeys: JArray (required)
  ##          : A list of tag keys to remove from the function.
  var path_601649 = newJObject()
  var query_601650 = newJObject()
  add(path_601649, "ARN", newJString(ARN))
  if tagKeys != nil:
    query_601650.add "tagKeys", tagKeys
  result = call_601648.call(path_601649, query_601650, nil, nil, nil)

var untagResource* = Call_UntagResource_601635(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2017-03-31/tags/{ARN}#tagKeys", validator: validate_UntagResource_601636,
    base: "/", url: url_UntagResource_601637, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionCode_601651 = ref object of OpenApiRestCall_600437
proc url_UpdateFunctionCode_601653(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/code")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateFunctionCode_601652(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Updates a Lambda function's code.</p> <p>The function's code is locked when you publish a version. You can't modify the code of a published version, only the unpublished version.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_601654 = path.getOrDefault("FunctionName")
  valid_601654 = validateParameter(valid_601654, JString, required = true,
                                 default = nil)
  if valid_601654 != nil:
    section.add "FunctionName", valid_601654
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601655 = header.getOrDefault("X-Amz-Date")
  valid_601655 = validateParameter(valid_601655, JString, required = false,
                                 default = nil)
  if valid_601655 != nil:
    section.add "X-Amz-Date", valid_601655
  var valid_601656 = header.getOrDefault("X-Amz-Security-Token")
  valid_601656 = validateParameter(valid_601656, JString, required = false,
                                 default = nil)
  if valid_601656 != nil:
    section.add "X-Amz-Security-Token", valid_601656
  var valid_601657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601657 = validateParameter(valid_601657, JString, required = false,
                                 default = nil)
  if valid_601657 != nil:
    section.add "X-Amz-Content-Sha256", valid_601657
  var valid_601658 = header.getOrDefault("X-Amz-Algorithm")
  valid_601658 = validateParameter(valid_601658, JString, required = false,
                                 default = nil)
  if valid_601658 != nil:
    section.add "X-Amz-Algorithm", valid_601658
  var valid_601659 = header.getOrDefault("X-Amz-Signature")
  valid_601659 = validateParameter(valid_601659, JString, required = false,
                                 default = nil)
  if valid_601659 != nil:
    section.add "X-Amz-Signature", valid_601659
  var valid_601660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601660 = validateParameter(valid_601660, JString, required = false,
                                 default = nil)
  if valid_601660 != nil:
    section.add "X-Amz-SignedHeaders", valid_601660
  var valid_601661 = header.getOrDefault("X-Amz-Credential")
  valid_601661 = validateParameter(valid_601661, JString, required = false,
                                 default = nil)
  if valid_601661 != nil:
    section.add "X-Amz-Credential", valid_601661
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601663: Call_UpdateFunctionCode_601651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a Lambda function's code.</p> <p>The function's code is locked when you publish a version. You can't modify the code of a published version, only the unpublished version.</p>
  ## 
  let valid = call_601663.validator(path, query, header, formData, body)
  let scheme = call_601663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601663.url(scheme.get, call_601663.host, call_601663.base,
                         call_601663.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601663, url, valid)

proc call*(call_601664: Call_UpdateFunctionCode_601651; FunctionName: string;
          body: JsonNode): Recallable =
  ## updateFunctionCode
  ## <p>Updates a Lambda function's code.</p> <p>The function's code is locked when you publish a version. You can't modify the code of a published version, only the unpublished version.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_601665 = newJObject()
  var body_601666 = newJObject()
  add(path_601665, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_601666 = body
  result = call_601664.call(path_601665, nil, nil, nil, body_601666)

var updateFunctionCode* = Call_UpdateFunctionCode_601651(
    name: "updateFunctionCode", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/code",
    validator: validate_UpdateFunctionCode_601652, base: "/",
    url: url_UpdateFunctionCode_601653, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
