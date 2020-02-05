
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
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
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddLayerVersionPermission_613267 = ref object of OpenApiRestCall_612658
proc url_AddLayerVersionPermission_613269(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AddLayerVersionPermission_613268(path: JsonNode; query: JsonNode;
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
  var valid_613270 = path.getOrDefault("VersionNumber")
  valid_613270 = validateParameter(valid_613270, JInt, required = true, default = nil)
  if valid_613270 != nil:
    section.add "VersionNumber", valid_613270
  var valid_613271 = path.getOrDefault("LayerName")
  valid_613271 = validateParameter(valid_613271, JString, required = true,
                                 default = nil)
  if valid_613271 != nil:
    section.add "LayerName", valid_613271
  result.add "path", section
  ## parameters in `query` object:
  ##   RevisionId: JString
  ##             : Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  section = newJObject()
  var valid_613272 = query.getOrDefault("RevisionId")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "RevisionId", valid_613272
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613273 = header.getOrDefault("X-Amz-Signature")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Signature", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Content-Sha256", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Date")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Date", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Credential")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Credential", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Security-Token")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Security-Token", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-Algorithm")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Algorithm", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-SignedHeaders", valid_613279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613281: Call_AddLayerVersionPermission_613267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds permissions to the resource-based policy of a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Use this action to grant layer usage permission to other accounts. You can grant permission to a single account, all AWS accounts, or all accounts in an organization.</p> <p>To revoke permission, call <a>RemoveLayerVersionPermission</a> with the statement ID that you specified when you added it.</p>
  ## 
  let valid = call_613281.validator(path, query, header, formData, body)
  let scheme = call_613281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613281.url(scheme.get, call_613281.host, call_613281.base,
                         call_613281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613281, url, valid)

proc call*(call_613282: Call_AddLayerVersionPermission_613267; VersionNumber: int;
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
  var path_613283 = newJObject()
  var query_613284 = newJObject()
  var body_613285 = newJObject()
  add(query_613284, "RevisionId", newJString(RevisionId))
  add(path_613283, "VersionNumber", newJInt(VersionNumber))
  add(path_613283, "LayerName", newJString(LayerName))
  if body != nil:
    body_613285 = body
  result = call_613282.call(path_613283, query_613284, nil, nil, body_613285)

var addLayerVersionPermission* = Call_AddLayerVersionPermission_613267(
    name: "addLayerVersionPermission", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy",
    validator: validate_AddLayerVersionPermission_613268, base: "/",
    url: url_AddLayerVersionPermission_613269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLayerVersionPolicy_612996 = ref object of OpenApiRestCall_612658
proc url_GetLayerVersionPolicy_612998(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetLayerVersionPolicy_612997(path: JsonNode; query: JsonNode;
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
  var valid_613124 = path.getOrDefault("VersionNumber")
  valid_613124 = validateParameter(valid_613124, JInt, required = true, default = nil)
  if valid_613124 != nil:
    section.add "VersionNumber", valid_613124
  var valid_613125 = path.getOrDefault("LayerName")
  valid_613125 = validateParameter(valid_613125, JString, required = true,
                                 default = nil)
  if valid_613125 != nil:
    section.add "LayerName", valid_613125
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613126 = header.getOrDefault("X-Amz-Signature")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Signature", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Content-Sha256", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Date")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Date", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Credential")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Credential", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Security-Token")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Security-Token", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-Algorithm")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-Algorithm", valid_613131
  var valid_613132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613132 = validateParameter(valid_613132, JString, required = false,
                                 default = nil)
  if valid_613132 != nil:
    section.add "X-Amz-SignedHeaders", valid_613132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613155: Call_GetLayerVersionPolicy_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the permission policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ## 
  let valid = call_613155.validator(path, query, header, formData, body)
  let scheme = call_613155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613155.url(scheme.get, call_613155.host, call_613155.base,
                         call_613155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613155, url, valid)

proc call*(call_613226: Call_GetLayerVersionPolicy_612996; VersionNumber: int;
          LayerName: string): Recallable =
  ## getLayerVersionPolicy
  ## Returns the permission policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_613227 = newJObject()
  add(path_613227, "VersionNumber", newJInt(VersionNumber))
  add(path_613227, "LayerName", newJString(LayerName))
  result = call_613226.call(path_613227, nil, nil, nil, nil)

var getLayerVersionPolicy* = Call_GetLayerVersionPolicy_612996(
    name: "getLayerVersionPolicy", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy",
    validator: validate_GetLayerVersionPolicy_612997, base: "/",
    url: url_GetLayerVersionPolicy_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddPermission_613302 = ref object of OpenApiRestCall_612658
proc url_AddPermission_613304(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AddPermission_613303(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Grants an AWS service or another account permission to use a function. You can apply the policy at the function level, or specify a qualifier to restrict access to a single version or alias. If you use a qualifier, the invoker must use the full Amazon Resource Name (ARN) of that version or alias to invoke the function.</p> <p>To grant permission to another account, specify the account ID as the <code>Principal</code>. For AWS services, the principal is a domain-style identifier defined by the service, like <code>s3.amazonaws.com</code> or <code>sns.amazonaws.com</code>. For AWS services, you can also specify the ARN or owning account of the associated resource as the <code>SourceArn</code> or <code>SourceAccount</code>. If you grant permission to a service principal without specifying the source, other accounts could potentially configure resources in their account to invoke your Lambda function.</p> <p>This action adds a statement to a resource-based permissions policy for the function. For more information about function policies, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">Lambda Function Policies</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_613305 = path.getOrDefault("FunctionName")
  valid_613305 = validateParameter(valid_613305, JString, required = true,
                                 default = nil)
  if valid_613305 != nil:
    section.add "FunctionName", valid_613305
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to add permissions to a published version of the function.
  section = newJObject()
  var valid_613306 = query.getOrDefault("Qualifier")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "Qualifier", valid_613306
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613307 = header.getOrDefault("X-Amz-Signature")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Signature", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Content-Sha256", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Date")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Date", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Credential")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Credential", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-Security-Token")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Security-Token", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-Algorithm")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Algorithm", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-SignedHeaders", valid_613313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613315: Call_AddPermission_613302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Grants an AWS service or another account permission to use a function. You can apply the policy at the function level, or specify a qualifier to restrict access to a single version or alias. If you use a qualifier, the invoker must use the full Amazon Resource Name (ARN) of that version or alias to invoke the function.</p> <p>To grant permission to another account, specify the account ID as the <code>Principal</code>. For AWS services, the principal is a domain-style identifier defined by the service, like <code>s3.amazonaws.com</code> or <code>sns.amazonaws.com</code>. For AWS services, you can also specify the ARN or owning account of the associated resource as the <code>SourceArn</code> or <code>SourceAccount</code>. If you grant permission to a service principal without specifying the source, other accounts could potentially configure resources in their account to invoke your Lambda function.</p> <p>This action adds a statement to a resource-based permissions policy for the function. For more information about function policies, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">Lambda Function Policies</a>. </p>
  ## 
  let valid = call_613315.validator(path, query, header, formData, body)
  let scheme = call_613315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613315.url(scheme.get, call_613315.host, call_613315.base,
                         call_613315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613315, url, valid)

proc call*(call_613316: Call_AddPermission_613302; FunctionName: string;
          body: JsonNode; Qualifier: string = ""): Recallable =
  ## addPermission
  ## <p>Grants an AWS service or another account permission to use a function. You can apply the policy at the function level, or specify a qualifier to restrict access to a single version or alias. If you use a qualifier, the invoker must use the full Amazon Resource Name (ARN) of that version or alias to invoke the function.</p> <p>To grant permission to another account, specify the account ID as the <code>Principal</code>. For AWS services, the principal is a domain-style identifier defined by the service, like <code>s3.amazonaws.com</code> or <code>sns.amazonaws.com</code>. For AWS services, you can also specify the ARN or owning account of the associated resource as the <code>SourceArn</code> or <code>SourceAccount</code>. If you grant permission to a service principal without specifying the source, other accounts could potentially configure resources in their account to invoke your Lambda function.</p> <p>This action adds a statement to a resource-based permissions policy for the function. For more information about function policies, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">Lambda Function Policies</a>. </p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to add permissions to a published version of the function.
  ##   body: JObject (required)
  var path_613317 = newJObject()
  var query_613318 = newJObject()
  var body_613319 = newJObject()
  add(path_613317, "FunctionName", newJString(FunctionName))
  add(query_613318, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_613319 = body
  result = call_613316.call(path_613317, query_613318, nil, nil, body_613319)

var addPermission* = Call_AddPermission_613302(name: "addPermission",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/policy",
    validator: validate_AddPermission_613303, base: "/", url: url_AddPermission_613304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPolicy_613286 = ref object of OpenApiRestCall_612658
proc url_GetPolicy_613288(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPolicy_613287(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613289 = path.getOrDefault("FunctionName")
  valid_613289 = validateParameter(valid_613289, JString, required = true,
                                 default = nil)
  if valid_613289 != nil:
    section.add "FunctionName", valid_613289
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to get the policy for that resource.
  section = newJObject()
  var valid_613290 = query.getOrDefault("Qualifier")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "Qualifier", valid_613290
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613291 = header.getOrDefault("X-Amz-Signature")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Signature", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Content-Sha256", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Date")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Date", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Credential")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Credential", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-Security-Token")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Security-Token", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-Algorithm")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Algorithm", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-SignedHeaders", valid_613297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613298: Call_GetPolicy_613286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">resource-based IAM policy</a> for a function, version, or alias.
  ## 
  let valid = call_613298.validator(path, query, header, formData, body)
  let scheme = call_613298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613298.url(scheme.get, call_613298.host, call_613298.base,
                         call_613298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613298, url, valid)

proc call*(call_613299: Call_GetPolicy_613286; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## getPolicy
  ## Returns the <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">resource-based IAM policy</a> for a function, version, or alias.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to get the policy for that resource.
  var path_613300 = newJObject()
  var query_613301 = newJObject()
  add(path_613300, "FunctionName", newJString(FunctionName))
  add(query_613301, "Qualifier", newJString(Qualifier))
  result = call_613299.call(path_613300, query_613301, nil, nil, nil)

var getPolicy* = Call_GetPolicy_613286(name: "getPolicy", meth: HttpMethod.HttpGet,
                                    host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/policy",
                                    validator: validate_GetPolicy_613287,
                                    base: "/", url: url_GetPolicy_613288,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlias_613338 = ref object of OpenApiRestCall_612658
proc url_CreateAlias_613340(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateAlias_613339(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613341 = path.getOrDefault("FunctionName")
  valid_613341 = validateParameter(valid_613341, JString, required = true,
                                 default = nil)
  if valid_613341 != nil:
    section.add "FunctionName", valid_613341
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613342 = header.getOrDefault("X-Amz-Signature")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-Signature", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Content-Sha256", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Date")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Date", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Credential")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Credential", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Security-Token")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Security-Token", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Algorithm")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Algorithm", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-SignedHeaders", valid_613348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613350: Call_CreateAlias_613338; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a> for a Lambda function version. Use aliases to provide clients with a function identifier that you can update to invoke a different version.</p> <p>You can also map an alias to split invocation requests between two versions. Use the <code>RoutingConfig</code> parameter to specify a second version and the percentage of invocation requests that it receives.</p>
  ## 
  let valid = call_613350.validator(path, query, header, formData, body)
  let scheme = call_613350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613350.url(scheme.get, call_613350.host, call_613350.base,
                         call_613350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613350, url, valid)

proc call*(call_613351: Call_CreateAlias_613338; FunctionName: string; body: JsonNode): Recallable =
  ## createAlias
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a> for a Lambda function version. Use aliases to provide clients with a function identifier that you can update to invoke a different version.</p> <p>You can also map an alias to split invocation requests between two versions. Use the <code>RoutingConfig</code> parameter to specify a second version and the percentage of invocation requests that it receives.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_613352 = newJObject()
  var body_613353 = newJObject()
  add(path_613352, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_613353 = body
  result = call_613351.call(path_613352, nil, nil, nil, body_613353)

var createAlias* = Call_CreateAlias_613338(name: "createAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases",
                                        validator: validate_CreateAlias_613339,
                                        base: "/", url: url_CreateAlias_613340,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAliases_613320 = ref object of OpenApiRestCall_612658
proc url_ListAliases_613322(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListAliases_613321(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613323 = path.getOrDefault("FunctionName")
  valid_613323 = validateParameter(valid_613323, JString, required = true,
                                 default = nil)
  if valid_613323 != nil:
    section.add "FunctionName", valid_613323
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   FunctionVersion: JString
  ##                  : Specify a function version to only list aliases that invoke that version.
  ##   MaxItems: JInt
  ##           : Limit the number of aliases returned.
  section = newJObject()
  var valid_613324 = query.getOrDefault("Marker")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "Marker", valid_613324
  var valid_613325 = query.getOrDefault("FunctionVersion")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "FunctionVersion", valid_613325
  var valid_613326 = query.getOrDefault("MaxItems")
  valid_613326 = validateParameter(valid_613326, JInt, required = false, default = nil)
  if valid_613326 != nil:
    section.add "MaxItems", valid_613326
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613327 = header.getOrDefault("X-Amz-Signature")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-Signature", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-Content-Sha256", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Date")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Date", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Credential")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Credential", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Security-Token")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Security-Token", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Algorithm")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Algorithm", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-SignedHeaders", valid_613333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613334: Call_ListAliases_613320; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">aliases</a> for a Lambda function.
  ## 
  let valid = call_613334.validator(path, query, header, formData, body)
  let scheme = call_613334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613334.url(scheme.get, call_613334.host, call_613334.base,
                         call_613334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613334, url, valid)

proc call*(call_613335: Call_ListAliases_613320; FunctionName: string;
          Marker: string = ""; FunctionVersion: string = ""; MaxItems: int = 0): Recallable =
  ## listAliases
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">aliases</a> for a Lambda function.
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   FunctionVersion: string
  ##                  : Specify a function version to only list aliases that invoke that version.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   MaxItems: int
  ##           : Limit the number of aliases returned.
  var path_613336 = newJObject()
  var query_613337 = newJObject()
  add(query_613337, "Marker", newJString(Marker))
  add(query_613337, "FunctionVersion", newJString(FunctionVersion))
  add(path_613336, "FunctionName", newJString(FunctionName))
  add(query_613337, "MaxItems", newJInt(MaxItems))
  result = call_613335.call(path_613336, query_613337, nil, nil, nil)

var listAliases* = Call_ListAliases_613320(name: "listAliases",
                                        meth: HttpMethod.HttpGet,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases",
                                        validator: validate_ListAliases_613321,
                                        base: "/", url: url_ListAliases_613322,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEventSourceMapping_613371 = ref object of OpenApiRestCall_612658
proc url_CreateEventSourceMapping_613373(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEventSourceMapping_613372(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a mapping between an event source and an AWS Lambda function. Lambda reads items from the event source and triggers the function.</p> <p>For details about each event source type, see the following topics.</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html">Using AWS Lambda with Amazon DynamoDB</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html">Using AWS Lambda with Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html">Using AWS Lambda with Amazon SQS</a> </p> </li> </ul> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> <li> <p> <code>ParallelizationFactor</code> - Process multiple batches from each shard concurrently.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613374 = header.getOrDefault("X-Amz-Signature")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Signature", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Content-Sha256", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Date")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Date", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Credential")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Credential", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Security-Token")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Security-Token", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Algorithm")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Algorithm", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-SignedHeaders", valid_613380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613382: Call_CreateEventSourceMapping_613371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a mapping between an event source and an AWS Lambda function. Lambda reads items from the event source and triggers the function.</p> <p>For details about each event source type, see the following topics.</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html">Using AWS Lambda with Amazon DynamoDB</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html">Using AWS Lambda with Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html">Using AWS Lambda with Amazon SQS</a> </p> </li> </ul> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> <li> <p> <code>ParallelizationFactor</code> - Process multiple batches from each shard concurrently.</p> </li> </ul>
  ## 
  let valid = call_613382.validator(path, query, header, formData, body)
  let scheme = call_613382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613382.url(scheme.get, call_613382.host, call_613382.base,
                         call_613382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613382, url, valid)

proc call*(call_613383: Call_CreateEventSourceMapping_613371; body: JsonNode): Recallable =
  ## createEventSourceMapping
  ## <p>Creates a mapping between an event source and an AWS Lambda function. Lambda reads items from the event source and triggers the function.</p> <p>For details about each event source type, see the following topics.</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html">Using AWS Lambda with Amazon DynamoDB</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html">Using AWS Lambda with Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html">Using AWS Lambda with Amazon SQS</a> </p> </li> </ul> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> <li> <p> <code>ParallelizationFactor</code> - Process multiple batches from each shard concurrently.</p> </li> </ul>
  ##   body: JObject (required)
  var body_613384 = newJObject()
  if body != nil:
    body_613384 = body
  result = call_613383.call(nil, nil, nil, nil, body_613384)

var createEventSourceMapping* = Call_CreateEventSourceMapping_613371(
    name: "createEventSourceMapping", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com", route: "/2015-03-31/event-source-mappings/",
    validator: validate_CreateEventSourceMapping_613372, base: "/",
    url: url_CreateEventSourceMapping_613373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventSourceMappings_613354 = ref object of OpenApiRestCall_612658
proc url_ListEventSourceMappings_613356(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEventSourceMappings_613355(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists event source mappings. Specify an <code>EventSourceArn</code> to only show event source mappings for a single event source.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : A pagination token returned by a previous call.
  ##   FunctionName: JString
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Version or Alias ARN</b> - 
  ## <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction:PROD</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it's limited to 64 characters in length.</p>
  ##   MaxItems: JInt
  ##           : The maximum number of event source mappings to return.
  ##   EventSourceArn: JString
  ##                 : <p>The Amazon Resource Name (ARN) of the event source.</p> <ul> <li> <p> <b>Amazon Kinesis</b> - The ARN of the data stream or a stream consumer.</p> </li> <li> <p> <b>Amazon DynamoDB Streams</b> - The ARN of the stream.</p> </li> <li> <p> <b>Amazon Simple Queue Service</b> - The ARN of the queue.</p> </li> </ul>
  section = newJObject()
  var valid_613357 = query.getOrDefault("Marker")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "Marker", valid_613357
  var valid_613358 = query.getOrDefault("FunctionName")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "FunctionName", valid_613358
  var valid_613359 = query.getOrDefault("MaxItems")
  valid_613359 = validateParameter(valid_613359, JInt, required = false, default = nil)
  if valid_613359 != nil:
    section.add "MaxItems", valid_613359
  var valid_613360 = query.getOrDefault("EventSourceArn")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "EventSourceArn", valid_613360
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613361 = header.getOrDefault("X-Amz-Signature")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Signature", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Content-Sha256", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Date")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Date", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Credential")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Credential", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-Security-Token")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-Security-Token", valid_613365
  var valid_613366 = header.getOrDefault("X-Amz-Algorithm")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "X-Amz-Algorithm", valid_613366
  var valid_613367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "X-Amz-SignedHeaders", valid_613367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613368: Call_ListEventSourceMappings_613354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists event source mappings. Specify an <code>EventSourceArn</code> to only show event source mappings for a single event source.
  ## 
  let valid = call_613368.validator(path, query, header, formData, body)
  let scheme = call_613368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613368.url(scheme.get, call_613368.host, call_613368.base,
                         call_613368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613368, url, valid)

proc call*(call_613369: Call_ListEventSourceMappings_613354; Marker: string = "";
          FunctionName: string = ""; MaxItems: int = 0; EventSourceArn: string = ""): Recallable =
  ## listEventSourceMappings
  ## Lists event source mappings. Specify an <code>EventSourceArn</code> to only show event source mappings for a single event source.
  ##   Marker: string
  ##         : A pagination token returned by a previous call.
  ##   FunctionName: string
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Version or Alias ARN</b> - 
  ## <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction:PROD</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it's limited to 64 characters in length.</p>
  ##   MaxItems: int
  ##           : The maximum number of event source mappings to return.
  ##   EventSourceArn: string
  ##                 : <p>The Amazon Resource Name (ARN) of the event source.</p> <ul> <li> <p> <b>Amazon Kinesis</b> - The ARN of the data stream or a stream consumer.</p> </li> <li> <p> <b>Amazon DynamoDB Streams</b> - The ARN of the stream.</p> </li> <li> <p> <b>Amazon Simple Queue Service</b> - The ARN of the queue.</p> </li> </ul>
  var query_613370 = newJObject()
  add(query_613370, "Marker", newJString(Marker))
  add(query_613370, "FunctionName", newJString(FunctionName))
  add(query_613370, "MaxItems", newJInt(MaxItems))
  add(query_613370, "EventSourceArn", newJString(EventSourceArn))
  result = call_613369.call(nil, query_613370, nil, nil, nil)

var listEventSourceMappings* = Call_ListEventSourceMappings_613354(
    name: "listEventSourceMappings", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2015-03-31/event-source-mappings/",
    validator: validate_ListEventSourceMappings_613355, base: "/",
    url: url_ListEventSourceMappings_613356, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunction_613385 = ref object of OpenApiRestCall_612658
proc url_CreateFunction_613387(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFunction_613386(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a Lambda function. To create a function, you need a <a href="https://docs.aws.amazon.com/lambda/latest/dg/deployment-package-v2.html">deployment package</a> and an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role">execution role</a>. The deployment package contains your function code. The execution role grants the function permission to use AWS services, such as Amazon CloudWatch Logs for log streaming and AWS X-Ray for request tracing.</p> <p>When you create a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute or so. During this time, you can't invoke or modify the function. The <code>State</code>, <code>StateReason</code>, and <code>StateReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the function is ready to invoke. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>A function has an unpublished version, and can have published versions and aliases. The unpublished version changes when you update your function's code and configuration. A published version is a snapshot of your function code and configuration that can't be changed. An alias is a named resource that maps to a version, and can be changed to map to a different version. Use the <code>Publish</code> parameter to create version <code>1</code> of your function from its initial configuration.</p> <p>The other parameters let you configure version-specific and function-level settings. You can modify version-specific settings later with <a>UpdateFunctionConfiguration</a>. Function-level settings apply to both the unpublished and published versions of the function, and include tags (<a>TagResource</a>) and per-function concurrency limits (<a>PutFunctionConcurrency</a>).</p> <p>If another account or an AWS service invokes your function, use <a>AddPermission</a> to grant permission by creating a resource-based IAM policy. You can grant permissions at the function level, on a version, or on an alias.</p> <p>To invoke your function directly, use <a>Invoke</a>. To invoke your function in response to events in other AWS services, create an event source mapping (<a>CreateEventSourceMapping</a>), or configure a function trigger in the other service. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-invocation.html">Invoking Functions</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613388 = header.getOrDefault("X-Amz-Signature")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Signature", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Content-Sha256", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Date")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Date", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Credential")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Credential", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Security-Token")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Security-Token", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Algorithm")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Algorithm", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-SignedHeaders", valid_613394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613396: Call_CreateFunction_613385; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Lambda function. To create a function, you need a <a href="https://docs.aws.amazon.com/lambda/latest/dg/deployment-package-v2.html">deployment package</a> and an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role">execution role</a>. The deployment package contains your function code. The execution role grants the function permission to use AWS services, such as Amazon CloudWatch Logs for log streaming and AWS X-Ray for request tracing.</p> <p>When you create a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute or so. During this time, you can't invoke or modify the function. The <code>State</code>, <code>StateReason</code>, and <code>StateReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the function is ready to invoke. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>A function has an unpublished version, and can have published versions and aliases. The unpublished version changes when you update your function's code and configuration. A published version is a snapshot of your function code and configuration that can't be changed. An alias is a named resource that maps to a version, and can be changed to map to a different version. Use the <code>Publish</code> parameter to create version <code>1</code> of your function from its initial configuration.</p> <p>The other parameters let you configure version-specific and function-level settings. You can modify version-specific settings later with <a>UpdateFunctionConfiguration</a>. Function-level settings apply to both the unpublished and published versions of the function, and include tags (<a>TagResource</a>) and per-function concurrency limits (<a>PutFunctionConcurrency</a>).</p> <p>If another account or an AWS service invokes your function, use <a>AddPermission</a> to grant permission by creating a resource-based IAM policy. You can grant permissions at the function level, on a version, or on an alias.</p> <p>To invoke your function directly, use <a>Invoke</a>. To invoke your function in response to events in other AWS services, create an event source mapping (<a>CreateEventSourceMapping</a>), or configure a function trigger in the other service. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-invocation.html">Invoking Functions</a>.</p>
  ## 
  let valid = call_613396.validator(path, query, header, formData, body)
  let scheme = call_613396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613396.url(scheme.get, call_613396.host, call_613396.base,
                         call_613396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613396, url, valid)

proc call*(call_613397: Call_CreateFunction_613385; body: JsonNode): Recallable =
  ## createFunction
  ## <p>Creates a Lambda function. To create a function, you need a <a href="https://docs.aws.amazon.com/lambda/latest/dg/deployment-package-v2.html">deployment package</a> and an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role">execution role</a>. The deployment package contains your function code. The execution role grants the function permission to use AWS services, such as Amazon CloudWatch Logs for log streaming and AWS X-Ray for request tracing.</p> <p>When you create a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute or so. During this time, you can't invoke or modify the function. The <code>State</code>, <code>StateReason</code>, and <code>StateReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the function is ready to invoke. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>A function has an unpublished version, and can have published versions and aliases. The unpublished version changes when you update your function's code and configuration. A published version is a snapshot of your function code and configuration that can't be changed. An alias is a named resource that maps to a version, and can be changed to map to a different version. Use the <code>Publish</code> parameter to create version <code>1</code> of your function from its initial configuration.</p> <p>The other parameters let you configure version-specific and function-level settings. You can modify version-specific settings later with <a>UpdateFunctionConfiguration</a>. Function-level settings apply to both the unpublished and published versions of the function, and include tags (<a>TagResource</a>) and per-function concurrency limits (<a>PutFunctionConcurrency</a>).</p> <p>If another account or an AWS service invokes your function, use <a>AddPermission</a> to grant permission by creating a resource-based IAM policy. You can grant permissions at the function level, on a version, or on an alias.</p> <p>To invoke your function directly, use <a>Invoke</a>. To invoke your function in response to events in other AWS services, create an event source mapping (<a>CreateEventSourceMapping</a>), or configure a function trigger in the other service. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-invocation.html">Invoking Functions</a>.</p>
  ##   body: JObject (required)
  var body_613398 = newJObject()
  if body != nil:
    body_613398 = body
  result = call_613397.call(nil, nil, nil, nil, body_613398)

var createFunction* = Call_CreateFunction_613385(name: "createFunction",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions", validator: validate_CreateFunction_613386,
    base: "/", url: url_CreateFunction_613387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAlias_613414 = ref object of OpenApiRestCall_612658
proc url_UpdateAlias_613416(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateAlias_613415(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613417 = path.getOrDefault("FunctionName")
  valid_613417 = validateParameter(valid_613417, JString, required = true,
                                 default = nil)
  if valid_613417 != nil:
    section.add "FunctionName", valid_613417
  var valid_613418 = path.getOrDefault("Name")
  valid_613418 = validateParameter(valid_613418, JString, required = true,
                                 default = nil)
  if valid_613418 != nil:
    section.add "Name", valid_613418
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613419 = header.getOrDefault("X-Amz-Signature")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Signature", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Content-Sha256", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Date")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Date", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Credential")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Credential", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Security-Token")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Security-Token", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Algorithm")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Algorithm", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-SignedHeaders", valid_613425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613427: Call_UpdateAlias_613414; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration of a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  let valid = call_613427.validator(path, query, header, formData, body)
  let scheme = call_613427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613427.url(scheme.get, call_613427.host, call_613427.base,
                         call_613427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613427, url, valid)

proc call*(call_613428: Call_UpdateAlias_613414; FunctionName: string; Name: string;
          body: JsonNode): Recallable =
  ## updateAlias
  ## Updates the configuration of a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: string (required)
  ##       : The name of the alias.
  ##   body: JObject (required)
  var path_613429 = newJObject()
  var body_613430 = newJObject()
  add(path_613429, "FunctionName", newJString(FunctionName))
  add(path_613429, "Name", newJString(Name))
  if body != nil:
    body_613430 = body
  result = call_613428.call(path_613429, nil, nil, nil, body_613430)

var updateAlias* = Call_UpdateAlias_613414(name: "updateAlias",
                                        meth: HttpMethod.HttpPut,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases/{Name}",
                                        validator: validate_UpdateAlias_613415,
                                        base: "/", url: url_UpdateAlias_613416,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAlias_613399 = ref object of OpenApiRestCall_612658
proc url_GetAlias_613401(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAlias_613400(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613402 = path.getOrDefault("FunctionName")
  valid_613402 = validateParameter(valid_613402, JString, required = true,
                                 default = nil)
  if valid_613402 != nil:
    section.add "FunctionName", valid_613402
  var valid_613403 = path.getOrDefault("Name")
  valid_613403 = validateParameter(valid_613403, JString, required = true,
                                 default = nil)
  if valid_613403 != nil:
    section.add "Name", valid_613403
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613404 = header.getOrDefault("X-Amz-Signature")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Signature", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Content-Sha256", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Date")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Date", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Credential")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Credential", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Security-Token")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Security-Token", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Algorithm")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Algorithm", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-SignedHeaders", valid_613410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613411: Call_GetAlias_613399; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  let valid = call_613411.validator(path, query, header, formData, body)
  let scheme = call_613411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613411.url(scheme.get, call_613411.host, call_613411.base,
                         call_613411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613411, url, valid)

proc call*(call_613412: Call_GetAlias_613399; FunctionName: string; Name: string): Recallable =
  ## getAlias
  ## Returns details about a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: string (required)
  ##       : The name of the alias.
  var path_613413 = newJObject()
  add(path_613413, "FunctionName", newJString(FunctionName))
  add(path_613413, "Name", newJString(Name))
  result = call_613412.call(path_613413, nil, nil, nil, nil)

var getAlias* = Call_GetAlias_613399(name: "getAlias", meth: HttpMethod.HttpGet,
                                  host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases/{Name}",
                                  validator: validate_GetAlias_613400, base: "/",
                                  url: url_GetAlias_613401,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlias_613431 = ref object of OpenApiRestCall_612658
proc url_DeleteAlias_613433(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAlias_613432(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613434 = path.getOrDefault("FunctionName")
  valid_613434 = validateParameter(valid_613434, JString, required = true,
                                 default = nil)
  if valid_613434 != nil:
    section.add "FunctionName", valid_613434
  var valid_613435 = path.getOrDefault("Name")
  valid_613435 = validateParameter(valid_613435, JString, required = true,
                                 default = nil)
  if valid_613435 != nil:
    section.add "Name", valid_613435
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613436 = header.getOrDefault("X-Amz-Signature")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Signature", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Content-Sha256", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Date")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Date", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-Credential")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Credential", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-Security-Token")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-Security-Token", valid_613440
  var valid_613441 = header.getOrDefault("X-Amz-Algorithm")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "X-Amz-Algorithm", valid_613441
  var valid_613442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613442 = validateParameter(valid_613442, JString, required = false,
                                 default = nil)
  if valid_613442 != nil:
    section.add "X-Amz-SignedHeaders", valid_613442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613443: Call_DeleteAlias_613431; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  let valid = call_613443.validator(path, query, header, formData, body)
  let scheme = call_613443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613443.url(scheme.get, call_613443.host, call_613443.base,
                         call_613443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613443, url, valid)

proc call*(call_613444: Call_DeleteAlias_613431; FunctionName: string; Name: string): Recallable =
  ## deleteAlias
  ## Deletes a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: string (required)
  ##       : The name of the alias.
  var path_613445 = newJObject()
  add(path_613445, "FunctionName", newJString(FunctionName))
  add(path_613445, "Name", newJString(Name))
  result = call_613444.call(path_613445, nil, nil, nil, nil)

var deleteAlias* = Call_DeleteAlias_613431(name: "deleteAlias",
                                        meth: HttpMethod.HttpDelete,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases/{Name}",
                                        validator: validate_DeleteAlias_613432,
                                        base: "/", url: url_DeleteAlias_613433,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEventSourceMapping_613460 = ref object of OpenApiRestCall_612658
proc url_UpdateEventSourceMapping_613462(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateEventSourceMapping_613461(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates an event source mapping. You can change the function that AWS Lambda invokes, or pause invocation and resume later from the same location.</p> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> <li> <p> <code>ParallelizationFactor</code> - Process multiple batches from each shard concurrently.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UUID: JString (required)
  ##       : The identifier of the event source mapping.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UUID` field"
  var valid_613463 = path.getOrDefault("UUID")
  valid_613463 = validateParameter(valid_613463, JString, required = true,
                                 default = nil)
  if valid_613463 != nil:
    section.add "UUID", valid_613463
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613464 = header.getOrDefault("X-Amz-Signature")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Signature", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Content-Sha256", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Date")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Date", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Credential")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Credential", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Security-Token")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Security-Token", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Algorithm")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Algorithm", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-SignedHeaders", valid_613470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613472: Call_UpdateEventSourceMapping_613460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an event source mapping. You can change the function that AWS Lambda invokes, or pause invocation and resume later from the same location.</p> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> <li> <p> <code>ParallelizationFactor</code> - Process multiple batches from each shard concurrently.</p> </li> </ul>
  ## 
  let valid = call_613472.validator(path, query, header, formData, body)
  let scheme = call_613472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613472.url(scheme.get, call_613472.host, call_613472.base,
                         call_613472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613472, url, valid)

proc call*(call_613473: Call_UpdateEventSourceMapping_613460; UUID: string;
          body: JsonNode): Recallable =
  ## updateEventSourceMapping
  ## <p>Updates an event source mapping. You can change the function that AWS Lambda invokes, or pause invocation and resume later from the same location.</p> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> <li> <p> <code>ParallelizationFactor</code> - Process multiple batches from each shard concurrently.</p> </li> </ul>
  ##   UUID: string (required)
  ##       : The identifier of the event source mapping.
  ##   body: JObject (required)
  var path_613474 = newJObject()
  var body_613475 = newJObject()
  add(path_613474, "UUID", newJString(UUID))
  if body != nil:
    body_613475 = body
  result = call_613473.call(path_613474, nil, nil, nil, body_613475)

var updateEventSourceMapping* = Call_UpdateEventSourceMapping_613460(
    name: "updateEventSourceMapping", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/event-source-mappings/{UUID}",
    validator: validate_UpdateEventSourceMapping_613461, base: "/",
    url: url_UpdateEventSourceMapping_613462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventSourceMapping_613446 = ref object of OpenApiRestCall_612658
proc url_GetEventSourceMapping_613448(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEventSourceMapping_613447(path: JsonNode; query: JsonNode;
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
  var valid_613449 = path.getOrDefault("UUID")
  valid_613449 = validateParameter(valid_613449, JString, required = true,
                                 default = nil)
  if valid_613449 != nil:
    section.add "UUID", valid_613449
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613450 = header.getOrDefault("X-Amz-Signature")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Signature", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Content-Sha256", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Date")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Date", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Credential")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Credential", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-Security-Token")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-Security-Token", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-Algorithm")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-Algorithm", valid_613455
  var valid_613456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613456 = validateParameter(valid_613456, JString, required = false,
                                 default = nil)
  if valid_613456 != nil:
    section.add "X-Amz-SignedHeaders", valid_613456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613457: Call_GetEventSourceMapping_613446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about an event source mapping. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.
  ## 
  let valid = call_613457.validator(path, query, header, formData, body)
  let scheme = call_613457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613457.url(scheme.get, call_613457.host, call_613457.base,
                         call_613457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613457, url, valid)

proc call*(call_613458: Call_GetEventSourceMapping_613446; UUID: string): Recallable =
  ## getEventSourceMapping
  ## Returns details about an event source mapping. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.
  ##   UUID: string (required)
  ##       : The identifier of the event source mapping.
  var path_613459 = newJObject()
  add(path_613459, "UUID", newJString(UUID))
  result = call_613458.call(path_613459, nil, nil, nil, nil)

var getEventSourceMapping* = Call_GetEventSourceMapping_613446(
    name: "getEventSourceMapping", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/event-source-mappings/{UUID}",
    validator: validate_GetEventSourceMapping_613447, base: "/",
    url: url_GetEventSourceMapping_613448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventSourceMapping_613476 = ref object of OpenApiRestCall_612658
proc url_DeleteEventSourceMapping_613478(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteEventSourceMapping_613477(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html">event source mapping</a>. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.</p> <p>When you delete an event source mapping, it enters a <code>Deleting</code> state and might not be completely deleted for several seconds.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UUID: JString (required)
  ##       : The identifier of the event source mapping.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UUID` field"
  var valid_613479 = path.getOrDefault("UUID")
  valid_613479 = validateParameter(valid_613479, JString, required = true,
                                 default = nil)
  if valid_613479 != nil:
    section.add "UUID", valid_613479
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613480 = header.getOrDefault("X-Amz-Signature")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Signature", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Content-Sha256", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Date")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Date", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Credential")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Credential", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Security-Token")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Security-Token", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-Algorithm")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Algorithm", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-SignedHeaders", valid_613486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613487: Call_DeleteEventSourceMapping_613476; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html">event source mapping</a>. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.</p> <p>When you delete an event source mapping, it enters a <code>Deleting</code> state and might not be completely deleted for several seconds.</p>
  ## 
  let valid = call_613487.validator(path, query, header, formData, body)
  let scheme = call_613487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613487.url(scheme.get, call_613487.host, call_613487.base,
                         call_613487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613487, url, valid)

proc call*(call_613488: Call_DeleteEventSourceMapping_613476; UUID: string): Recallable =
  ## deleteEventSourceMapping
  ## <p>Deletes an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html">event source mapping</a>. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.</p> <p>When you delete an event source mapping, it enters a <code>Deleting</code> state and might not be completely deleted for several seconds.</p>
  ##   UUID: string (required)
  ##       : The identifier of the event source mapping.
  var path_613489 = newJObject()
  add(path_613489, "UUID", newJString(UUID))
  result = call_613488.call(path_613489, nil, nil, nil, nil)

var deleteEventSourceMapping* = Call_DeleteEventSourceMapping_613476(
    name: "deleteEventSourceMapping", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/event-source-mappings/{UUID}",
    validator: validate_DeleteEventSourceMapping_613477, base: "/",
    url: url_DeleteEventSourceMapping_613478, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunction_613490 = ref object of OpenApiRestCall_612658
proc url_GetFunction_613492(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunction_613491(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613493 = path.getOrDefault("FunctionName")
  valid_613493 = validateParameter(valid_613493, JString, required = true,
                                 default = nil)
  if valid_613493 != nil:
    section.add "FunctionName", valid_613493
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to get details about a published version of the function.
  section = newJObject()
  var valid_613494 = query.getOrDefault("Qualifier")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "Qualifier", valid_613494
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613495 = header.getOrDefault("X-Amz-Signature")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Signature", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Content-Sha256", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Date")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Date", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Credential")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Credential", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Security-Token")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Security-Token", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-Algorithm")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-Algorithm", valid_613500
  var valid_613501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-SignedHeaders", valid_613501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613502: Call_GetFunction_613490; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the function or function version, with a link to download the deployment package that's valid for 10 minutes. If you specify a function version, only details that are specific to that version are returned.
  ## 
  let valid = call_613502.validator(path, query, header, formData, body)
  let scheme = call_613502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613502.url(scheme.get, call_613502.host, call_613502.base,
                         call_613502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613502, url, valid)

proc call*(call_613503: Call_GetFunction_613490; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## getFunction
  ## Returns information about the function or function version, with a link to download the deployment package that's valid for 10 minutes. If you specify a function version, only details that are specific to that version are returned.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to get details about a published version of the function.
  var path_613504 = newJObject()
  var query_613505 = newJObject()
  add(path_613504, "FunctionName", newJString(FunctionName))
  add(query_613505, "Qualifier", newJString(Qualifier))
  result = call_613503.call(path_613504, query_613505, nil, nil, nil)

var getFunction* = Call_GetFunction_613490(name: "getFunction",
                                        meth: HttpMethod.HttpGet,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}",
                                        validator: validate_GetFunction_613491,
                                        base: "/", url: url_GetFunction_613492,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunction_613506 = ref object of OpenApiRestCall_612658
proc url_DeleteFunction_613508(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFunction_613507(path: JsonNode; query: JsonNode;
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
  var valid_613509 = path.getOrDefault("FunctionName")
  valid_613509 = validateParameter(valid_613509, JString, required = true,
                                 default = nil)
  if valid_613509 != nil:
    section.add "FunctionName", valid_613509
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version to delete. You can't delete a version that's referenced by an alias.
  section = newJObject()
  var valid_613510 = query.getOrDefault("Qualifier")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "Qualifier", valid_613510
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613511 = header.getOrDefault("X-Amz-Signature")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Signature", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Content-Sha256", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Date")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Date", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-Credential")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Credential", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-Security-Token")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-Security-Token", valid_613515
  var valid_613516 = header.getOrDefault("X-Amz-Algorithm")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-Algorithm", valid_613516
  var valid_613517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-SignedHeaders", valid_613517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613518: Call_DeleteFunction_613506; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a Lambda function. To delete a specific function version, use the <code>Qualifier</code> parameter. Otherwise, all versions and aliases are deleted.</p> <p>To delete Lambda event source mappings that invoke a function, use <a>DeleteEventSourceMapping</a>. For AWS services and resources that invoke your function directly, delete the trigger in the service where you originally configured it.</p>
  ## 
  let valid = call_613518.validator(path, query, header, formData, body)
  let scheme = call_613518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613518.url(scheme.get, call_613518.host, call_613518.base,
                         call_613518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613518, url, valid)

proc call*(call_613519: Call_DeleteFunction_613506; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## deleteFunction
  ## <p>Deletes a Lambda function. To delete a specific function version, use the <code>Qualifier</code> parameter. Otherwise, all versions and aliases are deleted.</p> <p>To delete Lambda event source mappings that invoke a function, use <a>DeleteEventSourceMapping</a>. For AWS services and resources that invoke your function directly, delete the trigger in the service where you originally configured it.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function or version.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:1</code> (with version).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version to delete. You can't delete a version that's referenced by an alias.
  var path_613520 = newJObject()
  var query_613521 = newJObject()
  add(path_613520, "FunctionName", newJString(FunctionName))
  add(query_613521, "Qualifier", newJString(Qualifier))
  result = call_613519.call(path_613520, query_613521, nil, nil, nil)

var deleteFunction* = Call_DeleteFunction_613506(name: "deleteFunction",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}",
    validator: validate_DeleteFunction_613507, base: "/", url: url_DeleteFunction_613508,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFunctionConcurrency_613522 = ref object of OpenApiRestCall_612658
proc url_PutFunctionConcurrency_613524(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutFunctionConcurrency_613523(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the maximum number of simultaneous executions for a function, and reserves capacity for that concurrency level.</p> <p>Concurrency settings apply to the function as a whole, including all published versions and the unpublished version. Reserving concurrency both ensures that your function has capacity to process the specified number of events simultaneously, and prevents it from scaling beyond that level. Use <a>GetFunction</a> to see the current setting for a function.</p> <p>Use <a>GetAccountSettings</a> to see your Regional concurrency limit. You can reserve concurrency for as many functions as you like, as long as you leave at least 100 simultaneous executions unreserved for functions that aren't configured with a per-function limit. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/concurrent-executions.html">Managing Concurrency</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_613525 = path.getOrDefault("FunctionName")
  valid_613525 = validateParameter(valid_613525, JString, required = true,
                                 default = nil)
  if valid_613525 != nil:
    section.add "FunctionName", valid_613525
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613526 = header.getOrDefault("X-Amz-Signature")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Signature", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Content-Sha256", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Date")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Date", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Credential")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Credential", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-Security-Token")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-Security-Token", valid_613530
  var valid_613531 = header.getOrDefault("X-Amz-Algorithm")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-Algorithm", valid_613531
  var valid_613532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-SignedHeaders", valid_613532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613534: Call_PutFunctionConcurrency_613522; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the maximum number of simultaneous executions for a function, and reserves capacity for that concurrency level.</p> <p>Concurrency settings apply to the function as a whole, including all published versions and the unpublished version. Reserving concurrency both ensures that your function has capacity to process the specified number of events simultaneously, and prevents it from scaling beyond that level. Use <a>GetFunction</a> to see the current setting for a function.</p> <p>Use <a>GetAccountSettings</a> to see your Regional concurrency limit. You can reserve concurrency for as many functions as you like, as long as you leave at least 100 simultaneous executions unreserved for functions that aren't configured with a per-function limit. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/concurrent-executions.html">Managing Concurrency</a>.</p>
  ## 
  let valid = call_613534.validator(path, query, header, formData, body)
  let scheme = call_613534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613534.url(scheme.get, call_613534.host, call_613534.base,
                         call_613534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613534, url, valid)

proc call*(call_613535: Call_PutFunctionConcurrency_613522; FunctionName: string;
          body: JsonNode): Recallable =
  ## putFunctionConcurrency
  ## <p>Sets the maximum number of simultaneous executions for a function, and reserves capacity for that concurrency level.</p> <p>Concurrency settings apply to the function as a whole, including all published versions and the unpublished version. Reserving concurrency both ensures that your function has capacity to process the specified number of events simultaneously, and prevents it from scaling beyond that level. Use <a>GetFunction</a> to see the current setting for a function.</p> <p>Use <a>GetAccountSettings</a> to see your Regional concurrency limit. You can reserve concurrency for as many functions as you like, as long as you leave at least 100 simultaneous executions unreserved for functions that aren't configured with a per-function limit. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/concurrent-executions.html">Managing Concurrency</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_613536 = newJObject()
  var body_613537 = newJObject()
  add(path_613536, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_613537 = body
  result = call_613535.call(path_613536, nil, nil, nil, body_613537)

var putFunctionConcurrency* = Call_PutFunctionConcurrency_613522(
    name: "putFunctionConcurrency", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2017-10-31/functions/{FunctionName}/concurrency",
    validator: validate_PutFunctionConcurrency_613523, base: "/",
    url: url_PutFunctionConcurrency_613524, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionConcurrency_613538 = ref object of OpenApiRestCall_612658
proc url_DeleteFunctionConcurrency_613540(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFunctionConcurrency_613539(path: JsonNode; query: JsonNode;
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
  var valid_613541 = path.getOrDefault("FunctionName")
  valid_613541 = validateParameter(valid_613541, JString, required = true,
                                 default = nil)
  if valid_613541 != nil:
    section.add "FunctionName", valid_613541
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613542 = header.getOrDefault("X-Amz-Signature")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Signature", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Content-Sha256", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Date")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Date", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-Credential")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-Credential", valid_613545
  var valid_613546 = header.getOrDefault("X-Amz-Security-Token")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-Security-Token", valid_613546
  var valid_613547 = header.getOrDefault("X-Amz-Algorithm")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "X-Amz-Algorithm", valid_613547
  var valid_613548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "X-Amz-SignedHeaders", valid_613548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613549: Call_DeleteFunctionConcurrency_613538; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a concurrent execution limit from a function.
  ## 
  let valid = call_613549.validator(path, query, header, formData, body)
  let scheme = call_613549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613549.url(scheme.get, call_613549.host, call_613549.base,
                         call_613549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613549, url, valid)

proc call*(call_613550: Call_DeleteFunctionConcurrency_613538; FunctionName: string): Recallable =
  ## deleteFunctionConcurrency
  ## Removes a concurrent execution limit from a function.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  var path_613551 = newJObject()
  add(path_613551, "FunctionName", newJString(FunctionName))
  result = call_613550.call(path_613551, nil, nil, nil, nil)

var deleteFunctionConcurrency* = Call_DeleteFunctionConcurrency_613538(
    name: "deleteFunctionConcurrency", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2017-10-31/functions/{FunctionName}/concurrency",
    validator: validate_DeleteFunctionConcurrency_613539, base: "/",
    url: url_DeleteFunctionConcurrency_613540,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFunctionEventInvokeConfig_613568 = ref object of OpenApiRestCall_612658
proc url_PutFunctionEventInvokeConfig_613570(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-09-25/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/event-invoke-config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutFunctionEventInvokeConfig_613569(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Configures options for <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a> on a function, version, or alias.</p> <p>By default, Lambda retries an asynchronous invocation twice if the function returns an error. It retains events in a queue for up to six hours. When an event fails all processing attempts or stays in the asynchronous invocation queue for too long, Lambda discards it. To retain discarded events, configure a dead-letter queue with <a>UpdateFunctionConfiguration</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_613571 = path.getOrDefault("FunctionName")
  valid_613571 = validateParameter(valid_613571, JString, required = true,
                                 default = nil)
  if valid_613571 != nil:
    section.add "FunctionName", valid_613571
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_613572 = query.getOrDefault("Qualifier")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "Qualifier", valid_613572
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613573 = header.getOrDefault("X-Amz-Signature")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Signature", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Content-Sha256", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-Date")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-Date", valid_613575
  var valid_613576 = header.getOrDefault("X-Amz-Credential")
  valid_613576 = validateParameter(valid_613576, JString, required = false,
                                 default = nil)
  if valid_613576 != nil:
    section.add "X-Amz-Credential", valid_613576
  var valid_613577 = header.getOrDefault("X-Amz-Security-Token")
  valid_613577 = validateParameter(valid_613577, JString, required = false,
                                 default = nil)
  if valid_613577 != nil:
    section.add "X-Amz-Security-Token", valid_613577
  var valid_613578 = header.getOrDefault("X-Amz-Algorithm")
  valid_613578 = validateParameter(valid_613578, JString, required = false,
                                 default = nil)
  if valid_613578 != nil:
    section.add "X-Amz-Algorithm", valid_613578
  var valid_613579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613579 = validateParameter(valid_613579, JString, required = false,
                                 default = nil)
  if valid_613579 != nil:
    section.add "X-Amz-SignedHeaders", valid_613579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613581: Call_PutFunctionEventInvokeConfig_613568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures options for <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a> on a function, version, or alias.</p> <p>By default, Lambda retries an asynchronous invocation twice if the function returns an error. It retains events in a queue for up to six hours. When an event fails all processing attempts or stays in the asynchronous invocation queue for too long, Lambda discards it. To retain discarded events, configure a dead-letter queue with <a>UpdateFunctionConfiguration</a>.</p>
  ## 
  let valid = call_613581.validator(path, query, header, formData, body)
  let scheme = call_613581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613581.url(scheme.get, call_613581.host, call_613581.base,
                         call_613581.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613581, url, valid)

proc call*(call_613582: Call_PutFunctionEventInvokeConfig_613568;
          FunctionName: string; body: JsonNode; Qualifier: string = ""): Recallable =
  ## putFunctionEventInvokeConfig
  ## <p>Configures options for <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a> on a function, version, or alias.</p> <p>By default, Lambda retries an asynchronous invocation twice if the function returns an error. It retains events in a queue for up to six hours. When an event fails all processing attempts or stays in the asynchronous invocation queue for too long, Lambda discards it. To retain discarded events, configure a dead-letter queue with <a>UpdateFunctionConfiguration</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  ##   body: JObject (required)
  var path_613583 = newJObject()
  var query_613584 = newJObject()
  var body_613585 = newJObject()
  add(path_613583, "FunctionName", newJString(FunctionName))
  add(query_613584, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_613585 = body
  result = call_613582.call(path_613583, query_613584, nil, nil, body_613585)

var putFunctionEventInvokeConfig* = Call_PutFunctionEventInvokeConfig_613568(
    name: "putFunctionEventInvokeConfig", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_PutFunctionEventInvokeConfig_613569, base: "/",
    url: url_PutFunctionEventInvokeConfig_613570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionEventInvokeConfig_613586 = ref object of OpenApiRestCall_612658
proc url_UpdateFunctionEventInvokeConfig_613588(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-09-25/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/event-invoke-config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFunctionEventInvokeConfig_613587(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_613589 = path.getOrDefault("FunctionName")
  valid_613589 = validateParameter(valid_613589, JString, required = true,
                                 default = nil)
  if valid_613589 != nil:
    section.add "FunctionName", valid_613589
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_613590 = query.getOrDefault("Qualifier")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "Qualifier", valid_613590
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613591 = header.getOrDefault("X-Amz-Signature")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-Signature", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-Content-Sha256", valid_613592
  var valid_613593 = header.getOrDefault("X-Amz-Date")
  valid_613593 = validateParameter(valid_613593, JString, required = false,
                                 default = nil)
  if valid_613593 != nil:
    section.add "X-Amz-Date", valid_613593
  var valid_613594 = header.getOrDefault("X-Amz-Credential")
  valid_613594 = validateParameter(valid_613594, JString, required = false,
                                 default = nil)
  if valid_613594 != nil:
    section.add "X-Amz-Credential", valid_613594
  var valid_613595 = header.getOrDefault("X-Amz-Security-Token")
  valid_613595 = validateParameter(valid_613595, JString, required = false,
                                 default = nil)
  if valid_613595 != nil:
    section.add "X-Amz-Security-Token", valid_613595
  var valid_613596 = header.getOrDefault("X-Amz-Algorithm")
  valid_613596 = validateParameter(valid_613596, JString, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "X-Amz-Algorithm", valid_613596
  var valid_613597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613597 = validateParameter(valid_613597, JString, required = false,
                                 default = nil)
  if valid_613597 != nil:
    section.add "X-Amz-SignedHeaders", valid_613597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613599: Call_UpdateFunctionEventInvokeConfig_613586;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_613599.validator(path, query, header, formData, body)
  let scheme = call_613599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613599.url(scheme.get, call_613599.host, call_613599.base,
                         call_613599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613599, url, valid)

proc call*(call_613600: Call_UpdateFunctionEventInvokeConfig_613586;
          FunctionName: string; body: JsonNode; Qualifier: string = ""): Recallable =
  ## updateFunctionEventInvokeConfig
  ## <p>Updates the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  ##   body: JObject (required)
  var path_613601 = newJObject()
  var query_613602 = newJObject()
  var body_613603 = newJObject()
  add(path_613601, "FunctionName", newJString(FunctionName))
  add(query_613602, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_613603 = body
  result = call_613600.call(path_613601, query_613602, nil, nil, body_613603)

var updateFunctionEventInvokeConfig* = Call_UpdateFunctionEventInvokeConfig_613586(
    name: "updateFunctionEventInvokeConfig", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_UpdateFunctionEventInvokeConfig_613587, base: "/",
    url: url_UpdateFunctionEventInvokeConfig_613588,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionEventInvokeConfig_613552 = ref object of OpenApiRestCall_612658
proc url_GetFunctionEventInvokeConfig_613554(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-09-25/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/event-invoke-config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunctionEventInvokeConfig_613553(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_613555 = path.getOrDefault("FunctionName")
  valid_613555 = validateParameter(valid_613555, JString, required = true,
                                 default = nil)
  if valid_613555 != nil:
    section.add "FunctionName", valid_613555
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_613556 = query.getOrDefault("Qualifier")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "Qualifier", valid_613556
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613557 = header.getOrDefault("X-Amz-Signature")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Signature", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Content-Sha256", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-Date")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-Date", valid_613559
  var valid_613560 = header.getOrDefault("X-Amz-Credential")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "X-Amz-Credential", valid_613560
  var valid_613561 = header.getOrDefault("X-Amz-Security-Token")
  valid_613561 = validateParameter(valid_613561, JString, required = false,
                                 default = nil)
  if valid_613561 != nil:
    section.add "X-Amz-Security-Token", valid_613561
  var valid_613562 = header.getOrDefault("X-Amz-Algorithm")
  valid_613562 = validateParameter(valid_613562, JString, required = false,
                                 default = nil)
  if valid_613562 != nil:
    section.add "X-Amz-Algorithm", valid_613562
  var valid_613563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613563 = validateParameter(valid_613563, JString, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "X-Amz-SignedHeaders", valid_613563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613564: Call_GetFunctionEventInvokeConfig_613552; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_613564.validator(path, query, header, formData, body)
  let scheme = call_613564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613564.url(scheme.get, call_613564.host, call_613564.base,
                         call_613564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613564, url, valid)

proc call*(call_613565: Call_GetFunctionEventInvokeConfig_613552;
          FunctionName: string; Qualifier: string = ""): Recallable =
  ## getFunctionEventInvokeConfig
  ## <p>Retrieves the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  var path_613566 = newJObject()
  var query_613567 = newJObject()
  add(path_613566, "FunctionName", newJString(FunctionName))
  add(query_613567, "Qualifier", newJString(Qualifier))
  result = call_613565.call(path_613566, query_613567, nil, nil, nil)

var getFunctionEventInvokeConfig* = Call_GetFunctionEventInvokeConfig_613552(
    name: "getFunctionEventInvokeConfig", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_GetFunctionEventInvokeConfig_613553, base: "/",
    url: url_GetFunctionEventInvokeConfig_613554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionEventInvokeConfig_613604 = ref object of OpenApiRestCall_612658
proc url_DeleteFunctionEventInvokeConfig_613606(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-09-25/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/event-invoke-config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFunctionEventInvokeConfig_613605(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_613607 = path.getOrDefault("FunctionName")
  valid_613607 = validateParameter(valid_613607, JString, required = true,
                                 default = nil)
  if valid_613607 != nil:
    section.add "FunctionName", valid_613607
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_613608 = query.getOrDefault("Qualifier")
  valid_613608 = validateParameter(valid_613608, JString, required = false,
                                 default = nil)
  if valid_613608 != nil:
    section.add "Qualifier", valid_613608
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613609 = header.getOrDefault("X-Amz-Signature")
  valid_613609 = validateParameter(valid_613609, JString, required = false,
                                 default = nil)
  if valid_613609 != nil:
    section.add "X-Amz-Signature", valid_613609
  var valid_613610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613610 = validateParameter(valid_613610, JString, required = false,
                                 default = nil)
  if valid_613610 != nil:
    section.add "X-Amz-Content-Sha256", valid_613610
  var valid_613611 = header.getOrDefault("X-Amz-Date")
  valid_613611 = validateParameter(valid_613611, JString, required = false,
                                 default = nil)
  if valid_613611 != nil:
    section.add "X-Amz-Date", valid_613611
  var valid_613612 = header.getOrDefault("X-Amz-Credential")
  valid_613612 = validateParameter(valid_613612, JString, required = false,
                                 default = nil)
  if valid_613612 != nil:
    section.add "X-Amz-Credential", valid_613612
  var valid_613613 = header.getOrDefault("X-Amz-Security-Token")
  valid_613613 = validateParameter(valid_613613, JString, required = false,
                                 default = nil)
  if valid_613613 != nil:
    section.add "X-Amz-Security-Token", valid_613613
  var valid_613614 = header.getOrDefault("X-Amz-Algorithm")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "X-Amz-Algorithm", valid_613614
  var valid_613615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "X-Amz-SignedHeaders", valid_613615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613616: Call_DeleteFunctionEventInvokeConfig_613604;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_613616.validator(path, query, header, formData, body)
  let scheme = call_613616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613616.url(scheme.get, call_613616.host, call_613616.base,
                         call_613616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613616, url, valid)

proc call*(call_613617: Call_DeleteFunctionEventInvokeConfig_613604;
          FunctionName: string; Qualifier: string = ""): Recallable =
  ## deleteFunctionEventInvokeConfig
  ## <p>Deletes the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  var path_613618 = newJObject()
  var query_613619 = newJObject()
  add(path_613618, "FunctionName", newJString(FunctionName))
  add(query_613619, "Qualifier", newJString(Qualifier))
  result = call_613617.call(path_613618, query_613619, nil, nil, nil)

var deleteFunctionEventInvokeConfig* = Call_DeleteFunctionEventInvokeConfig_613604(
    name: "deleteFunctionEventInvokeConfig", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_DeleteFunctionEventInvokeConfig_613605, base: "/",
    url: url_DeleteFunctionEventInvokeConfig_613606,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLayerVersion_613620 = ref object of OpenApiRestCall_612658
proc url_GetLayerVersion_613622(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetLayerVersion_613621(path: JsonNode; query: JsonNode;
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
  var valid_613623 = path.getOrDefault("VersionNumber")
  valid_613623 = validateParameter(valid_613623, JInt, required = true, default = nil)
  if valid_613623 != nil:
    section.add "VersionNumber", valid_613623
  var valid_613624 = path.getOrDefault("LayerName")
  valid_613624 = validateParameter(valid_613624, JString, required = true,
                                 default = nil)
  if valid_613624 != nil:
    section.add "LayerName", valid_613624
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613625 = header.getOrDefault("X-Amz-Signature")
  valid_613625 = validateParameter(valid_613625, JString, required = false,
                                 default = nil)
  if valid_613625 != nil:
    section.add "X-Amz-Signature", valid_613625
  var valid_613626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613626 = validateParameter(valid_613626, JString, required = false,
                                 default = nil)
  if valid_613626 != nil:
    section.add "X-Amz-Content-Sha256", valid_613626
  var valid_613627 = header.getOrDefault("X-Amz-Date")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "X-Amz-Date", valid_613627
  var valid_613628 = header.getOrDefault("X-Amz-Credential")
  valid_613628 = validateParameter(valid_613628, JString, required = false,
                                 default = nil)
  if valid_613628 != nil:
    section.add "X-Amz-Credential", valid_613628
  var valid_613629 = header.getOrDefault("X-Amz-Security-Token")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "X-Amz-Security-Token", valid_613629
  var valid_613630 = header.getOrDefault("X-Amz-Algorithm")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "X-Amz-Algorithm", valid_613630
  var valid_613631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-SignedHeaders", valid_613631
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613632: Call_GetLayerVersion_613620; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ## 
  let valid = call_613632.validator(path, query, header, formData, body)
  let scheme = call_613632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613632.url(scheme.get, call_613632.host, call_613632.base,
                         call_613632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613632, url, valid)

proc call*(call_613633: Call_GetLayerVersion_613620; VersionNumber: int;
          LayerName: string): Recallable =
  ## getLayerVersion
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_613634 = newJObject()
  add(path_613634, "VersionNumber", newJInt(VersionNumber))
  add(path_613634, "LayerName", newJString(LayerName))
  result = call_613633.call(path_613634, nil, nil, nil, nil)

var getLayerVersion* = Call_GetLayerVersion_613620(name: "getLayerVersion",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}",
    validator: validate_GetLayerVersion_613621, base: "/", url: url_GetLayerVersion_613622,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLayerVersion_613635 = ref object of OpenApiRestCall_612658
proc url_DeleteLayerVersion_613637(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteLayerVersion_613636(path: JsonNode; query: JsonNode;
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
  var valid_613638 = path.getOrDefault("VersionNumber")
  valid_613638 = validateParameter(valid_613638, JInt, required = true, default = nil)
  if valid_613638 != nil:
    section.add "VersionNumber", valid_613638
  var valid_613639 = path.getOrDefault("LayerName")
  valid_613639 = validateParameter(valid_613639, JString, required = true,
                                 default = nil)
  if valid_613639 != nil:
    section.add "LayerName", valid_613639
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613640 = header.getOrDefault("X-Amz-Signature")
  valid_613640 = validateParameter(valid_613640, JString, required = false,
                                 default = nil)
  if valid_613640 != nil:
    section.add "X-Amz-Signature", valid_613640
  var valid_613641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613641 = validateParameter(valid_613641, JString, required = false,
                                 default = nil)
  if valid_613641 != nil:
    section.add "X-Amz-Content-Sha256", valid_613641
  var valid_613642 = header.getOrDefault("X-Amz-Date")
  valid_613642 = validateParameter(valid_613642, JString, required = false,
                                 default = nil)
  if valid_613642 != nil:
    section.add "X-Amz-Date", valid_613642
  var valid_613643 = header.getOrDefault("X-Amz-Credential")
  valid_613643 = validateParameter(valid_613643, JString, required = false,
                                 default = nil)
  if valid_613643 != nil:
    section.add "X-Amz-Credential", valid_613643
  var valid_613644 = header.getOrDefault("X-Amz-Security-Token")
  valid_613644 = validateParameter(valid_613644, JString, required = false,
                                 default = nil)
  if valid_613644 != nil:
    section.add "X-Amz-Security-Token", valid_613644
  var valid_613645 = header.getOrDefault("X-Amz-Algorithm")
  valid_613645 = validateParameter(valid_613645, JString, required = false,
                                 default = nil)
  if valid_613645 != nil:
    section.add "X-Amz-Algorithm", valid_613645
  var valid_613646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "X-Amz-SignedHeaders", valid_613646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613647: Call_DeleteLayerVersion_613635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Deleted versions can no longer be viewed or added to functions. To avoid breaking functions, a copy of the version remains in Lambda until no functions refer to it.
  ## 
  let valid = call_613647.validator(path, query, header, formData, body)
  let scheme = call_613647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613647.url(scheme.get, call_613647.host, call_613647.base,
                         call_613647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613647, url, valid)

proc call*(call_613648: Call_DeleteLayerVersion_613635; VersionNumber: int;
          LayerName: string): Recallable =
  ## deleteLayerVersion
  ## Deletes a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Deleted versions can no longer be viewed or added to functions. To avoid breaking functions, a copy of the version remains in Lambda until no functions refer to it.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_613649 = newJObject()
  add(path_613649, "VersionNumber", newJInt(VersionNumber))
  add(path_613649, "LayerName", newJString(LayerName))
  result = call_613648.call(path_613649, nil, nil, nil, nil)

var deleteLayerVersion* = Call_DeleteLayerVersion_613635(
    name: "deleteLayerVersion", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}",
    validator: validate_DeleteLayerVersion_613636, base: "/",
    url: url_DeleteLayerVersion_613637, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutProvisionedConcurrencyConfig_613666 = ref object of OpenApiRestCall_612658
proc url_PutProvisionedConcurrencyConfig_613668(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-09-30/functions/"),
               (kind: VariableSegment, value: "FunctionName"), (
        kind: ConstantSegment, value: "/provisioned-concurrency#Qualifier")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutProvisionedConcurrencyConfig_613667(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds a provisioned concurrency configuration to a function's alias or version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_613669 = path.getOrDefault("FunctionName")
  valid_613669 = validateParameter(valid_613669, JString, required = true,
                                 default = nil)
  if valid_613669 != nil:
    section.add "FunctionName", valid_613669
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString (required)
  ##            : The version number or alias name.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Qualifier` field"
  var valid_613670 = query.getOrDefault("Qualifier")
  valid_613670 = validateParameter(valid_613670, JString, required = true,
                                 default = nil)
  if valid_613670 != nil:
    section.add "Qualifier", valid_613670
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613671 = header.getOrDefault("X-Amz-Signature")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "X-Amz-Signature", valid_613671
  var valid_613672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "X-Amz-Content-Sha256", valid_613672
  var valid_613673 = header.getOrDefault("X-Amz-Date")
  valid_613673 = validateParameter(valid_613673, JString, required = false,
                                 default = nil)
  if valid_613673 != nil:
    section.add "X-Amz-Date", valid_613673
  var valid_613674 = header.getOrDefault("X-Amz-Credential")
  valid_613674 = validateParameter(valid_613674, JString, required = false,
                                 default = nil)
  if valid_613674 != nil:
    section.add "X-Amz-Credential", valid_613674
  var valid_613675 = header.getOrDefault("X-Amz-Security-Token")
  valid_613675 = validateParameter(valid_613675, JString, required = false,
                                 default = nil)
  if valid_613675 != nil:
    section.add "X-Amz-Security-Token", valid_613675
  var valid_613676 = header.getOrDefault("X-Amz-Algorithm")
  valid_613676 = validateParameter(valid_613676, JString, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "X-Amz-Algorithm", valid_613676
  var valid_613677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613677 = validateParameter(valid_613677, JString, required = false,
                                 default = nil)
  if valid_613677 != nil:
    section.add "X-Amz-SignedHeaders", valid_613677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613679: Call_PutProvisionedConcurrencyConfig_613666;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a provisioned concurrency configuration to a function's alias or version.
  ## 
  let valid = call_613679.validator(path, query, header, formData, body)
  let scheme = call_613679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613679.url(scheme.get, call_613679.host, call_613679.base,
                         call_613679.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613679, url, valid)

proc call*(call_613680: Call_PutProvisionedConcurrencyConfig_613666;
          FunctionName: string; Qualifier: string; body: JsonNode): Recallable =
  ## putProvisionedConcurrencyConfig
  ## Adds a provisioned concurrency configuration to a function's alias or version.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string (required)
  ##            : The version number or alias name.
  ##   body: JObject (required)
  var path_613681 = newJObject()
  var query_613682 = newJObject()
  var body_613683 = newJObject()
  add(path_613681, "FunctionName", newJString(FunctionName))
  add(query_613682, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_613683 = body
  result = call_613680.call(path_613681, query_613682, nil, nil, body_613683)

var putProvisionedConcurrencyConfig* = Call_PutProvisionedConcurrencyConfig_613666(
    name: "putProvisionedConcurrencyConfig", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#Qualifier",
    validator: validate_PutProvisionedConcurrencyConfig_613667, base: "/",
    url: url_PutProvisionedConcurrencyConfig_613668,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProvisionedConcurrencyConfig_613650 = ref object of OpenApiRestCall_612658
proc url_GetProvisionedConcurrencyConfig_613652(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-09-30/functions/"),
               (kind: VariableSegment, value: "FunctionName"), (
        kind: ConstantSegment, value: "/provisioned-concurrency#Qualifier")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetProvisionedConcurrencyConfig_613651(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the provisioned concurrency configuration for a function's alias or version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_613653 = path.getOrDefault("FunctionName")
  valid_613653 = validateParameter(valid_613653, JString, required = true,
                                 default = nil)
  if valid_613653 != nil:
    section.add "FunctionName", valid_613653
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString (required)
  ##            : The version number or alias name.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Qualifier` field"
  var valid_613654 = query.getOrDefault("Qualifier")
  valid_613654 = validateParameter(valid_613654, JString, required = true,
                                 default = nil)
  if valid_613654 != nil:
    section.add "Qualifier", valid_613654
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613655 = header.getOrDefault("X-Amz-Signature")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "X-Amz-Signature", valid_613655
  var valid_613656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-Content-Sha256", valid_613656
  var valid_613657 = header.getOrDefault("X-Amz-Date")
  valid_613657 = validateParameter(valid_613657, JString, required = false,
                                 default = nil)
  if valid_613657 != nil:
    section.add "X-Amz-Date", valid_613657
  var valid_613658 = header.getOrDefault("X-Amz-Credential")
  valid_613658 = validateParameter(valid_613658, JString, required = false,
                                 default = nil)
  if valid_613658 != nil:
    section.add "X-Amz-Credential", valid_613658
  var valid_613659 = header.getOrDefault("X-Amz-Security-Token")
  valid_613659 = validateParameter(valid_613659, JString, required = false,
                                 default = nil)
  if valid_613659 != nil:
    section.add "X-Amz-Security-Token", valid_613659
  var valid_613660 = header.getOrDefault("X-Amz-Algorithm")
  valid_613660 = validateParameter(valid_613660, JString, required = false,
                                 default = nil)
  if valid_613660 != nil:
    section.add "X-Amz-Algorithm", valid_613660
  var valid_613661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613661 = validateParameter(valid_613661, JString, required = false,
                                 default = nil)
  if valid_613661 != nil:
    section.add "X-Amz-SignedHeaders", valid_613661
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613662: Call_GetProvisionedConcurrencyConfig_613650;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the provisioned concurrency configuration for a function's alias or version.
  ## 
  let valid = call_613662.validator(path, query, header, formData, body)
  let scheme = call_613662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613662.url(scheme.get, call_613662.host, call_613662.base,
                         call_613662.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613662, url, valid)

proc call*(call_613663: Call_GetProvisionedConcurrencyConfig_613650;
          FunctionName: string; Qualifier: string): Recallable =
  ## getProvisionedConcurrencyConfig
  ## Retrieves the provisioned concurrency configuration for a function's alias or version.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string (required)
  ##            : The version number or alias name.
  var path_613664 = newJObject()
  var query_613665 = newJObject()
  add(path_613664, "FunctionName", newJString(FunctionName))
  add(query_613665, "Qualifier", newJString(Qualifier))
  result = call_613663.call(path_613664, query_613665, nil, nil, nil)

var getProvisionedConcurrencyConfig* = Call_GetProvisionedConcurrencyConfig_613650(
    name: "getProvisionedConcurrencyConfig", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#Qualifier",
    validator: validate_GetProvisionedConcurrencyConfig_613651, base: "/",
    url: url_GetProvisionedConcurrencyConfig_613652,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisionedConcurrencyConfig_613684 = ref object of OpenApiRestCall_612658
proc url_DeleteProvisionedConcurrencyConfig_613686(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-09-30/functions/"),
               (kind: VariableSegment, value: "FunctionName"), (
        kind: ConstantSegment, value: "/provisioned-concurrency#Qualifier")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteProvisionedConcurrencyConfig_613685(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the provisioned concurrency configuration for a function.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_613687 = path.getOrDefault("FunctionName")
  valid_613687 = validateParameter(valid_613687, JString, required = true,
                                 default = nil)
  if valid_613687 != nil:
    section.add "FunctionName", valid_613687
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString (required)
  ##            : The version number or alias name.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Qualifier` field"
  var valid_613688 = query.getOrDefault("Qualifier")
  valid_613688 = validateParameter(valid_613688, JString, required = true,
                                 default = nil)
  if valid_613688 != nil:
    section.add "Qualifier", valid_613688
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613689 = header.getOrDefault("X-Amz-Signature")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "X-Amz-Signature", valid_613689
  var valid_613690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "X-Amz-Content-Sha256", valid_613690
  var valid_613691 = header.getOrDefault("X-Amz-Date")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-Date", valid_613691
  var valid_613692 = header.getOrDefault("X-Amz-Credential")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-Credential", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-Security-Token")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Security-Token", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Algorithm")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Algorithm", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-SignedHeaders", valid_613695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613696: Call_DeleteProvisionedConcurrencyConfig_613684;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the provisioned concurrency configuration for a function.
  ## 
  let valid = call_613696.validator(path, query, header, formData, body)
  let scheme = call_613696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613696.url(scheme.get, call_613696.host, call_613696.base,
                         call_613696.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613696, url, valid)

proc call*(call_613697: Call_DeleteProvisionedConcurrencyConfig_613684;
          FunctionName: string; Qualifier: string): Recallable =
  ## deleteProvisionedConcurrencyConfig
  ## Deletes the provisioned concurrency configuration for a function.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string (required)
  ##            : The version number or alias name.
  var path_613698 = newJObject()
  var query_613699 = newJObject()
  add(path_613698, "FunctionName", newJString(FunctionName))
  add(query_613699, "Qualifier", newJString(Qualifier))
  result = call_613697.call(path_613698, query_613699, nil, nil, nil)

var deleteProvisionedConcurrencyConfig* = Call_DeleteProvisionedConcurrencyConfig_613684(
    name: "deleteProvisionedConcurrencyConfig", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#Qualifier",
    validator: validate_DeleteProvisionedConcurrencyConfig_613685, base: "/",
    url: url_DeleteProvisionedConcurrencyConfig_613686,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_613700 = ref object of OpenApiRestCall_612658
proc url_GetAccountSettings_613702(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAccountSettings_613701(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613703 = header.getOrDefault("X-Amz-Signature")
  valid_613703 = validateParameter(valid_613703, JString, required = false,
                                 default = nil)
  if valid_613703 != nil:
    section.add "X-Amz-Signature", valid_613703
  var valid_613704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613704 = validateParameter(valid_613704, JString, required = false,
                                 default = nil)
  if valid_613704 != nil:
    section.add "X-Amz-Content-Sha256", valid_613704
  var valid_613705 = header.getOrDefault("X-Amz-Date")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "X-Amz-Date", valid_613705
  var valid_613706 = header.getOrDefault("X-Amz-Credential")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Credential", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-Security-Token")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Security-Token", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-Algorithm")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Algorithm", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-SignedHeaders", valid_613709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613710: Call_GetAccountSettings_613700; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details about your account's <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limits</a> and usage in an AWS Region.
  ## 
  let valid = call_613710.validator(path, query, header, formData, body)
  let scheme = call_613710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613710.url(scheme.get, call_613710.host, call_613710.base,
                         call_613710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613710, url, valid)

proc call*(call_613711: Call_GetAccountSettings_613700): Recallable =
  ## getAccountSettings
  ## Retrieves details about your account's <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limits</a> and usage in an AWS Region.
  result = call_613711.call(nil, nil, nil, nil, nil)

var getAccountSettings* = Call_GetAccountSettings_613700(
    name: "getAccountSettings", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2016-08-19/account-settings/",
    validator: validate_GetAccountSettings_613701, base: "/",
    url: url_GetAccountSettings_613702, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionConcurrency_613712 = ref object of OpenApiRestCall_612658
proc url_GetFunctionConcurrency_613714(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-09-30/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/concurrency")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunctionConcurrency_613713(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns details about the concurrency configuration for a function. To set a concurrency limit for a function, use <a>PutFunctionConcurrency</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_613715 = path.getOrDefault("FunctionName")
  valid_613715 = validateParameter(valid_613715, JString, required = true,
                                 default = nil)
  if valid_613715 != nil:
    section.add "FunctionName", valid_613715
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613716 = header.getOrDefault("X-Amz-Signature")
  valid_613716 = validateParameter(valid_613716, JString, required = false,
                                 default = nil)
  if valid_613716 != nil:
    section.add "X-Amz-Signature", valid_613716
  var valid_613717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613717 = validateParameter(valid_613717, JString, required = false,
                                 default = nil)
  if valid_613717 != nil:
    section.add "X-Amz-Content-Sha256", valid_613717
  var valid_613718 = header.getOrDefault("X-Amz-Date")
  valid_613718 = validateParameter(valid_613718, JString, required = false,
                                 default = nil)
  if valid_613718 != nil:
    section.add "X-Amz-Date", valid_613718
  var valid_613719 = header.getOrDefault("X-Amz-Credential")
  valid_613719 = validateParameter(valid_613719, JString, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "X-Amz-Credential", valid_613719
  var valid_613720 = header.getOrDefault("X-Amz-Security-Token")
  valid_613720 = validateParameter(valid_613720, JString, required = false,
                                 default = nil)
  if valid_613720 != nil:
    section.add "X-Amz-Security-Token", valid_613720
  var valid_613721 = header.getOrDefault("X-Amz-Algorithm")
  valid_613721 = validateParameter(valid_613721, JString, required = false,
                                 default = nil)
  if valid_613721 != nil:
    section.add "X-Amz-Algorithm", valid_613721
  var valid_613722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613722 = validateParameter(valid_613722, JString, required = false,
                                 default = nil)
  if valid_613722 != nil:
    section.add "X-Amz-SignedHeaders", valid_613722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613723: Call_GetFunctionConcurrency_613712; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about the concurrency configuration for a function. To set a concurrency limit for a function, use <a>PutFunctionConcurrency</a>.
  ## 
  let valid = call_613723.validator(path, query, header, formData, body)
  let scheme = call_613723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613723.url(scheme.get, call_613723.host, call_613723.base,
                         call_613723.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613723, url, valid)

proc call*(call_613724: Call_GetFunctionConcurrency_613712; FunctionName: string): Recallable =
  ## getFunctionConcurrency
  ## Returns details about the concurrency configuration for a function. To set a concurrency limit for a function, use <a>PutFunctionConcurrency</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  var path_613725 = newJObject()
  add(path_613725, "FunctionName", newJString(FunctionName))
  result = call_613724.call(path_613725, nil, nil, nil, nil)

var getFunctionConcurrency* = Call_GetFunctionConcurrency_613712(
    name: "getFunctionConcurrency", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2019-09-30/functions/{FunctionName}/concurrency",
    validator: validate_GetFunctionConcurrency_613713, base: "/",
    url: url_GetFunctionConcurrency_613714, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionConfiguration_613742 = ref object of OpenApiRestCall_612658
proc url_UpdateFunctionConfiguration_613744(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFunctionConfiguration_613743(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modify the version-specific settings of a Lambda function.</p> <p>When you update a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute. During this time, you can't modify the function, but you can still invoke it. The <code>LastUpdateStatus</code>, <code>LastUpdateStatusReason</code>, and <code>LastUpdateStatusReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the update is complete and the function is processing events with the new configuration. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>These settings can vary between versions of a function and are locked when you publish a version. You can't modify the configuration of a published version, only the unpublished version.</p> <p>To configure function concurrency, use <a>PutFunctionConcurrency</a>. To grant invoke permissions to an account or AWS service, use <a>AddPermission</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_613745 = path.getOrDefault("FunctionName")
  valid_613745 = validateParameter(valid_613745, JString, required = true,
                                 default = nil)
  if valid_613745 != nil:
    section.add "FunctionName", valid_613745
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613746 = header.getOrDefault("X-Amz-Signature")
  valid_613746 = validateParameter(valid_613746, JString, required = false,
                                 default = nil)
  if valid_613746 != nil:
    section.add "X-Amz-Signature", valid_613746
  var valid_613747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613747 = validateParameter(valid_613747, JString, required = false,
                                 default = nil)
  if valid_613747 != nil:
    section.add "X-Amz-Content-Sha256", valid_613747
  var valid_613748 = header.getOrDefault("X-Amz-Date")
  valid_613748 = validateParameter(valid_613748, JString, required = false,
                                 default = nil)
  if valid_613748 != nil:
    section.add "X-Amz-Date", valid_613748
  var valid_613749 = header.getOrDefault("X-Amz-Credential")
  valid_613749 = validateParameter(valid_613749, JString, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "X-Amz-Credential", valid_613749
  var valid_613750 = header.getOrDefault("X-Amz-Security-Token")
  valid_613750 = validateParameter(valid_613750, JString, required = false,
                                 default = nil)
  if valid_613750 != nil:
    section.add "X-Amz-Security-Token", valid_613750
  var valid_613751 = header.getOrDefault("X-Amz-Algorithm")
  valid_613751 = validateParameter(valid_613751, JString, required = false,
                                 default = nil)
  if valid_613751 != nil:
    section.add "X-Amz-Algorithm", valid_613751
  var valid_613752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613752 = validateParameter(valid_613752, JString, required = false,
                                 default = nil)
  if valid_613752 != nil:
    section.add "X-Amz-SignedHeaders", valid_613752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613754: Call_UpdateFunctionConfiguration_613742; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modify the version-specific settings of a Lambda function.</p> <p>When you update a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute. During this time, you can't modify the function, but you can still invoke it. The <code>LastUpdateStatus</code>, <code>LastUpdateStatusReason</code>, and <code>LastUpdateStatusReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the update is complete and the function is processing events with the new configuration. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>These settings can vary between versions of a function and are locked when you publish a version. You can't modify the configuration of a published version, only the unpublished version.</p> <p>To configure function concurrency, use <a>PutFunctionConcurrency</a>. To grant invoke permissions to an account or AWS service, use <a>AddPermission</a>.</p>
  ## 
  let valid = call_613754.validator(path, query, header, formData, body)
  let scheme = call_613754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613754.url(scheme.get, call_613754.host, call_613754.base,
                         call_613754.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613754, url, valid)

proc call*(call_613755: Call_UpdateFunctionConfiguration_613742;
          FunctionName: string; body: JsonNode): Recallable =
  ## updateFunctionConfiguration
  ## <p>Modify the version-specific settings of a Lambda function.</p> <p>When you update a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute. During this time, you can't modify the function, but you can still invoke it. The <code>LastUpdateStatus</code>, <code>LastUpdateStatusReason</code>, and <code>LastUpdateStatusReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the update is complete and the function is processing events with the new configuration. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>These settings can vary between versions of a function and are locked when you publish a version. You can't modify the configuration of a published version, only the unpublished version.</p> <p>To configure function concurrency, use <a>PutFunctionConcurrency</a>. To grant invoke permissions to an account or AWS service, use <a>AddPermission</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_613756 = newJObject()
  var body_613757 = newJObject()
  add(path_613756, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_613757 = body
  result = call_613755.call(path_613756, nil, nil, nil, body_613757)

var updateFunctionConfiguration* = Call_UpdateFunctionConfiguration_613742(
    name: "updateFunctionConfiguration", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/configuration",
    validator: validate_UpdateFunctionConfiguration_613743, base: "/",
    url: url_UpdateFunctionConfiguration_613744,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionConfiguration_613726 = ref object of OpenApiRestCall_612658
proc url_GetFunctionConfiguration_613728(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunctionConfiguration_613727(path: JsonNode; query: JsonNode;
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
  var valid_613729 = path.getOrDefault("FunctionName")
  valid_613729 = validateParameter(valid_613729, JString, required = true,
                                 default = nil)
  if valid_613729 != nil:
    section.add "FunctionName", valid_613729
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to get details about a published version of the function.
  section = newJObject()
  var valid_613730 = query.getOrDefault("Qualifier")
  valid_613730 = validateParameter(valid_613730, JString, required = false,
                                 default = nil)
  if valid_613730 != nil:
    section.add "Qualifier", valid_613730
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613731 = header.getOrDefault("X-Amz-Signature")
  valid_613731 = validateParameter(valid_613731, JString, required = false,
                                 default = nil)
  if valid_613731 != nil:
    section.add "X-Amz-Signature", valid_613731
  var valid_613732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613732 = validateParameter(valid_613732, JString, required = false,
                                 default = nil)
  if valid_613732 != nil:
    section.add "X-Amz-Content-Sha256", valid_613732
  var valid_613733 = header.getOrDefault("X-Amz-Date")
  valid_613733 = validateParameter(valid_613733, JString, required = false,
                                 default = nil)
  if valid_613733 != nil:
    section.add "X-Amz-Date", valid_613733
  var valid_613734 = header.getOrDefault("X-Amz-Credential")
  valid_613734 = validateParameter(valid_613734, JString, required = false,
                                 default = nil)
  if valid_613734 != nil:
    section.add "X-Amz-Credential", valid_613734
  var valid_613735 = header.getOrDefault("X-Amz-Security-Token")
  valid_613735 = validateParameter(valid_613735, JString, required = false,
                                 default = nil)
  if valid_613735 != nil:
    section.add "X-Amz-Security-Token", valid_613735
  var valid_613736 = header.getOrDefault("X-Amz-Algorithm")
  valid_613736 = validateParameter(valid_613736, JString, required = false,
                                 default = nil)
  if valid_613736 != nil:
    section.add "X-Amz-Algorithm", valid_613736
  var valid_613737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613737 = validateParameter(valid_613737, JString, required = false,
                                 default = nil)
  if valid_613737 != nil:
    section.add "X-Amz-SignedHeaders", valid_613737
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613738: Call_GetFunctionConfiguration_613726; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the version-specific settings of a Lambda function or version. The output includes only options that can vary between versions of a function. To modify these settings, use <a>UpdateFunctionConfiguration</a>.</p> <p>To get all of a function's details, including function-level settings, use <a>GetFunction</a>.</p>
  ## 
  let valid = call_613738.validator(path, query, header, formData, body)
  let scheme = call_613738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613738.url(scheme.get, call_613738.host, call_613738.base,
                         call_613738.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613738, url, valid)

proc call*(call_613739: Call_GetFunctionConfiguration_613726; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## getFunctionConfiguration
  ## <p>Returns the version-specific settings of a Lambda function or version. The output includes only options that can vary between versions of a function. To modify these settings, use <a>UpdateFunctionConfiguration</a>.</p> <p>To get all of a function's details, including function-level settings, use <a>GetFunction</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to get details about a published version of the function.
  var path_613740 = newJObject()
  var query_613741 = newJObject()
  add(path_613740, "FunctionName", newJString(FunctionName))
  add(query_613741, "Qualifier", newJString(Qualifier))
  result = call_613739.call(path_613740, query_613741, nil, nil, nil)

var getFunctionConfiguration* = Call_GetFunctionConfiguration_613726(
    name: "getFunctionConfiguration", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/configuration",
    validator: validate_GetFunctionConfiguration_613727, base: "/",
    url: url_GetFunctionConfiguration_613728, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLayerVersionByArn_613758 = ref object of OpenApiRestCall_612658
proc url_GetLayerVersionByArn_613760(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLayerVersionByArn_613759(path: JsonNode; query: JsonNode;
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
  var valid_613774 = query.getOrDefault("find")
  valid_613774 = validateParameter(valid_613774, JString, required = true,
                                 default = newJString("LayerVersion"))
  if valid_613774 != nil:
    section.add "find", valid_613774
  var valid_613775 = query.getOrDefault("Arn")
  valid_613775 = validateParameter(valid_613775, JString, required = true,
                                 default = nil)
  if valid_613775 != nil:
    section.add "Arn", valid_613775
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613776 = header.getOrDefault("X-Amz-Signature")
  valid_613776 = validateParameter(valid_613776, JString, required = false,
                                 default = nil)
  if valid_613776 != nil:
    section.add "X-Amz-Signature", valid_613776
  var valid_613777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613777 = validateParameter(valid_613777, JString, required = false,
                                 default = nil)
  if valid_613777 != nil:
    section.add "X-Amz-Content-Sha256", valid_613777
  var valid_613778 = header.getOrDefault("X-Amz-Date")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-Date", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-Credential")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-Credential", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-Security-Token")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-Security-Token", valid_613780
  var valid_613781 = header.getOrDefault("X-Amz-Algorithm")
  valid_613781 = validateParameter(valid_613781, JString, required = false,
                                 default = nil)
  if valid_613781 != nil:
    section.add "X-Amz-Algorithm", valid_613781
  var valid_613782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613782 = validateParameter(valid_613782, JString, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "X-Amz-SignedHeaders", valid_613782
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613783: Call_GetLayerVersionByArn_613758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ## 
  let valid = call_613783.validator(path, query, header, formData, body)
  let scheme = call_613783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613783.url(scheme.get, call_613783.host, call_613783.base,
                         call_613783.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613783, url, valid)

proc call*(call_613784: Call_GetLayerVersionByArn_613758; Arn: string;
          find: string = "LayerVersion"): Recallable =
  ## getLayerVersionByArn
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ##   find: string (required)
  ##   Arn: string (required)
  ##      : The ARN of the layer version.
  var query_613785 = newJObject()
  add(query_613785, "find", newJString(find))
  add(query_613785, "Arn", newJString(Arn))
  result = call_613784.call(nil, query_613785, nil, nil, nil)

var getLayerVersionByArn* = Call_GetLayerVersionByArn_613758(
    name: "getLayerVersionByArn", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers#find=LayerVersion&Arn",
    validator: validate_GetLayerVersionByArn_613759, base: "/",
    url: url_GetLayerVersionByArn_613760, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Invoke_613786 = ref object of OpenApiRestCall_612658
proc url_Invoke_613788(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_Invoke_613787(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Invokes a Lambda function. You can invoke a function synchronously (and wait for the response), or asynchronously. To invoke a function asynchronously, set <code>InvocationType</code> to <code>Event</code>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-sync.html">synchronous invocation</a>, details about the function response, including errors, are included in the response body and headers. For either invocation type, you can find more information in the <a href="https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions.html">execution log</a> and <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-x-ray.html">trace</a>.</p> <p>When an error occurs, your function may be invoked multiple times. Retry behavior varies by error type, client, event source, and invocation type. For example, if you invoke a function asynchronously and it returns an error, Lambda executes the function up to two more times. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/retries-on-errors.html">Retry Behavior</a>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a>, Lambda adds events to a queue before sending them to your function. If your function does not have enough capacity to keep up with the queue, events may be lost. Occasionally, your function may receive the same event multiple times, even if no error occurs. To retain events that were not processed, configure your function with a <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#dlq">dead-letter queue</a>.</p> <p>The status code in the API response doesn't reflect function errors. Error codes are reserved for errors that prevent your function from executing, such as permissions errors, <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limit errors</a>, or issues with your function's code and configuration. For example, Lambda returns <code>TooManyRequestsException</code> if executing the function would cause you to exceed a concurrency limit at either the account level (<code>ConcurrentInvocationLimitExceeded</code>) or function level (<code>ReservedFunctionConcurrentInvocationLimitExceeded</code>).</p> <p>For functions with a long timeout, your client might be disconnected during synchronous invocation while it waits for a response. Configure your HTTP client, SDK, firewall, proxy, or operating system to allow for long connections with timeout or keep-alive settings.</p> <p>This operation requires permission for the <code>lambda:InvokeFunction</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_613789 = path.getOrDefault("FunctionName")
  valid_613789 = validateParameter(valid_613789, JString, required = true,
                                 default = nil)
  if valid_613789 != nil:
    section.add "FunctionName", valid_613789
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to invoke a published version of the function.
  section = newJObject()
  var valid_613790 = query.getOrDefault("Qualifier")
  valid_613790 = validateParameter(valid_613790, JString, required = false,
                                 default = nil)
  if valid_613790 != nil:
    section.add "Qualifier", valid_613790
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Invocation-Type: JString
  ##                        : <p>Choose from the following options.</p> <ul> <li> <p> <code>RequestResponse</code> (default) - Invoke the function synchronously. Keep the connection open until the function returns a response or times out. The API response includes the function response and additional data.</p> </li> <li> <p> <code>Event</code> - Invoke the function asynchronously. Send events that fail multiple times to the function's dead-letter queue (if it's configured). The API response only includes a status code.</p> </li> <li> <p> <code>DryRun</code> - Validate parameter values and verify that the user or role has permission to invoke the function.</p> </li> </ul>
  ##   X-Amz-Signature: JString
  ##   X-Amz-Client-Context: JString
  ##                       : Up to 3583 bytes of base64-encoded data about the invoking client to pass to the function in the context object.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Log-Type: JString
  ##                 : Set to <code>Tail</code> to include the execution log in the response.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613791 = header.getOrDefault("X-Amz-Invocation-Type")
  valid_613791 = validateParameter(valid_613791, JString, required = false,
                                 default = newJString("Event"))
  if valid_613791 != nil:
    section.add "X-Amz-Invocation-Type", valid_613791
  var valid_613792 = header.getOrDefault("X-Amz-Signature")
  valid_613792 = validateParameter(valid_613792, JString, required = false,
                                 default = nil)
  if valid_613792 != nil:
    section.add "X-Amz-Signature", valid_613792
  var valid_613793 = header.getOrDefault("X-Amz-Client-Context")
  valid_613793 = validateParameter(valid_613793, JString, required = false,
                                 default = nil)
  if valid_613793 != nil:
    section.add "X-Amz-Client-Context", valid_613793
  var valid_613794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613794 = validateParameter(valid_613794, JString, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "X-Amz-Content-Sha256", valid_613794
  var valid_613795 = header.getOrDefault("X-Amz-Date")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "X-Amz-Date", valid_613795
  var valid_613796 = header.getOrDefault("X-Amz-Credential")
  valid_613796 = validateParameter(valid_613796, JString, required = false,
                                 default = nil)
  if valid_613796 != nil:
    section.add "X-Amz-Credential", valid_613796
  var valid_613797 = header.getOrDefault("X-Amz-Security-Token")
  valid_613797 = validateParameter(valid_613797, JString, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "X-Amz-Security-Token", valid_613797
  var valid_613798 = header.getOrDefault("X-Amz-Log-Type")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = newJString("None"))
  if valid_613798 != nil:
    section.add "X-Amz-Log-Type", valid_613798
  var valid_613799 = header.getOrDefault("X-Amz-Algorithm")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-Algorithm", valid_613799
  var valid_613800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613800 = validateParameter(valid_613800, JString, required = false,
                                 default = nil)
  if valid_613800 != nil:
    section.add "X-Amz-SignedHeaders", valid_613800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613802: Call_Invoke_613786; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Invokes a Lambda function. You can invoke a function synchronously (and wait for the response), or asynchronously. To invoke a function asynchronously, set <code>InvocationType</code> to <code>Event</code>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-sync.html">synchronous invocation</a>, details about the function response, including errors, are included in the response body and headers. For either invocation type, you can find more information in the <a href="https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions.html">execution log</a> and <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-x-ray.html">trace</a>.</p> <p>When an error occurs, your function may be invoked multiple times. Retry behavior varies by error type, client, event source, and invocation type. For example, if you invoke a function asynchronously and it returns an error, Lambda executes the function up to two more times. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/retries-on-errors.html">Retry Behavior</a>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a>, Lambda adds events to a queue before sending them to your function. If your function does not have enough capacity to keep up with the queue, events may be lost. Occasionally, your function may receive the same event multiple times, even if no error occurs. To retain events that were not processed, configure your function with a <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#dlq">dead-letter queue</a>.</p> <p>The status code in the API response doesn't reflect function errors. Error codes are reserved for errors that prevent your function from executing, such as permissions errors, <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limit errors</a>, or issues with your function's code and configuration. For example, Lambda returns <code>TooManyRequestsException</code> if executing the function would cause you to exceed a concurrency limit at either the account level (<code>ConcurrentInvocationLimitExceeded</code>) or function level (<code>ReservedFunctionConcurrentInvocationLimitExceeded</code>).</p> <p>For functions with a long timeout, your client might be disconnected during synchronous invocation while it waits for a response. Configure your HTTP client, SDK, firewall, proxy, or operating system to allow for long connections with timeout or keep-alive settings.</p> <p>This operation requires permission for the <code>lambda:InvokeFunction</code> action.</p>
  ## 
  let valid = call_613802.validator(path, query, header, formData, body)
  let scheme = call_613802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613802.url(scheme.get, call_613802.host, call_613802.base,
                         call_613802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613802, url, valid)

proc call*(call_613803: Call_Invoke_613786; FunctionName: string; body: JsonNode;
          Qualifier: string = ""): Recallable =
  ## invoke
  ## <p>Invokes a Lambda function. You can invoke a function synchronously (and wait for the response), or asynchronously. To invoke a function asynchronously, set <code>InvocationType</code> to <code>Event</code>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-sync.html">synchronous invocation</a>, details about the function response, including errors, are included in the response body and headers. For either invocation type, you can find more information in the <a href="https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions.html">execution log</a> and <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-x-ray.html">trace</a>.</p> <p>When an error occurs, your function may be invoked multiple times. Retry behavior varies by error type, client, event source, and invocation type. For example, if you invoke a function asynchronously and it returns an error, Lambda executes the function up to two more times. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/retries-on-errors.html">Retry Behavior</a>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a>, Lambda adds events to a queue before sending them to your function. If your function does not have enough capacity to keep up with the queue, events may be lost. Occasionally, your function may receive the same event multiple times, even if no error occurs. To retain events that were not processed, configure your function with a <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#dlq">dead-letter queue</a>.</p> <p>The status code in the API response doesn't reflect function errors. Error codes are reserved for errors that prevent your function from executing, such as permissions errors, <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limit errors</a>, or issues with your function's code and configuration. For example, Lambda returns <code>TooManyRequestsException</code> if executing the function would cause you to exceed a concurrency limit at either the account level (<code>ConcurrentInvocationLimitExceeded</code>) or function level (<code>ReservedFunctionConcurrentInvocationLimitExceeded</code>).</p> <p>For functions with a long timeout, your client might be disconnected during synchronous invocation while it waits for a response. Configure your HTTP client, SDK, firewall, proxy, or operating system to allow for long connections with timeout or keep-alive settings.</p> <p>This operation requires permission for the <code>lambda:InvokeFunction</code> action.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to invoke a published version of the function.
  ##   body: JObject (required)
  var path_613804 = newJObject()
  var query_613805 = newJObject()
  var body_613806 = newJObject()
  add(path_613804, "FunctionName", newJString(FunctionName))
  add(query_613805, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_613806 = body
  result = call_613803.call(path_613804, query_613805, nil, nil, body_613806)

var invoke* = Call_Invoke_613786(name: "invoke", meth: HttpMethod.HttpPost,
                              host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/invocations",
                              validator: validate_Invoke_613787, base: "/",
                              url: url_Invoke_613788,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvokeAsync_613807 = ref object of OpenApiRestCall_612658
proc url_InvokeAsync_613809(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_InvokeAsync_613808(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613810 = path.getOrDefault("FunctionName")
  valid_613810 = validateParameter(valid_613810, JString, required = true,
                                 default = nil)
  if valid_613810 != nil:
    section.add "FunctionName", valid_613810
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613811 = header.getOrDefault("X-Amz-Signature")
  valid_613811 = validateParameter(valid_613811, JString, required = false,
                                 default = nil)
  if valid_613811 != nil:
    section.add "X-Amz-Signature", valid_613811
  var valid_613812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "X-Amz-Content-Sha256", valid_613812
  var valid_613813 = header.getOrDefault("X-Amz-Date")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Date", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Credential")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Credential", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-Security-Token")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-Security-Token", valid_613815
  var valid_613816 = header.getOrDefault("X-Amz-Algorithm")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-Algorithm", valid_613816
  var valid_613817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613817 = validateParameter(valid_613817, JString, required = false,
                                 default = nil)
  if valid_613817 != nil:
    section.add "X-Amz-SignedHeaders", valid_613817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613819: Call_InvokeAsync_613807; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <important> <p>For asynchronous function invocation, use <a>Invoke</a>.</p> </important> <p>Invokes a function asynchronously.</p>
  ## 
  let valid = call_613819.validator(path, query, header, formData, body)
  let scheme = call_613819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613819.url(scheme.get, call_613819.host, call_613819.base,
                         call_613819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613819, url, valid)

proc call*(call_613820: Call_InvokeAsync_613807; FunctionName: string; body: JsonNode): Recallable =
  ## invokeAsync
  ## <important> <p>For asynchronous function invocation, use <a>Invoke</a>.</p> </important> <p>Invokes a function asynchronously.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_613821 = newJObject()
  var body_613822 = newJObject()
  add(path_613821, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_613822 = body
  result = call_613820.call(path_613821, nil, nil, nil, body_613822)

var invokeAsync* = Call_InvokeAsync_613807(name: "invokeAsync",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com", route: "/2014-11-13/functions/{FunctionName}/invoke-async/",
                                        validator: validate_InvokeAsync_613808,
                                        base: "/", url: url_InvokeAsync_613809,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionEventInvokeConfigs_613823 = ref object of OpenApiRestCall_612658
proc url_ListFunctionEventInvokeConfigs_613825(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-09-25/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/event-invoke-config/list")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListFunctionEventInvokeConfigs_613824(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a list of configurations for asynchronous invocation for a function.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_613826 = path.getOrDefault("FunctionName")
  valid_613826 = validateParameter(valid_613826, JString, required = true,
                                 default = nil)
  if valid_613826 != nil:
    section.add "FunctionName", valid_613826
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : The maximum number of configurations to return.
  section = newJObject()
  var valid_613827 = query.getOrDefault("Marker")
  valid_613827 = validateParameter(valid_613827, JString, required = false,
                                 default = nil)
  if valid_613827 != nil:
    section.add "Marker", valid_613827
  var valid_613828 = query.getOrDefault("MaxItems")
  valid_613828 = validateParameter(valid_613828, JInt, required = false, default = nil)
  if valid_613828 != nil:
    section.add "MaxItems", valid_613828
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613829 = header.getOrDefault("X-Amz-Signature")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-Signature", valid_613829
  var valid_613830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "X-Amz-Content-Sha256", valid_613830
  var valid_613831 = header.getOrDefault("X-Amz-Date")
  valid_613831 = validateParameter(valid_613831, JString, required = false,
                                 default = nil)
  if valid_613831 != nil:
    section.add "X-Amz-Date", valid_613831
  var valid_613832 = header.getOrDefault("X-Amz-Credential")
  valid_613832 = validateParameter(valid_613832, JString, required = false,
                                 default = nil)
  if valid_613832 != nil:
    section.add "X-Amz-Credential", valid_613832
  var valid_613833 = header.getOrDefault("X-Amz-Security-Token")
  valid_613833 = validateParameter(valid_613833, JString, required = false,
                                 default = nil)
  if valid_613833 != nil:
    section.add "X-Amz-Security-Token", valid_613833
  var valid_613834 = header.getOrDefault("X-Amz-Algorithm")
  valid_613834 = validateParameter(valid_613834, JString, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "X-Amz-Algorithm", valid_613834
  var valid_613835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613835 = validateParameter(valid_613835, JString, required = false,
                                 default = nil)
  if valid_613835 != nil:
    section.add "X-Amz-SignedHeaders", valid_613835
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613836: Call_ListFunctionEventInvokeConfigs_613823; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of configurations for asynchronous invocation for a function.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_613836.validator(path, query, header, formData, body)
  let scheme = call_613836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613836.url(scheme.get, call_613836.host, call_613836.base,
                         call_613836.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613836, url, valid)

proc call*(call_613837: Call_ListFunctionEventInvokeConfigs_613823;
          FunctionName: string; Marker: string = ""; MaxItems: int = 0): Recallable =
  ## listFunctionEventInvokeConfigs
  ## <p>Retrieves a list of configurations for asynchronous invocation for a function.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   MaxItems: int
  ##           : The maximum number of configurations to return.
  var path_613838 = newJObject()
  var query_613839 = newJObject()
  add(query_613839, "Marker", newJString(Marker))
  add(path_613838, "FunctionName", newJString(FunctionName))
  add(query_613839, "MaxItems", newJInt(MaxItems))
  result = call_613837.call(path_613838, query_613839, nil, nil, nil)

var listFunctionEventInvokeConfigs* = Call_ListFunctionEventInvokeConfigs_613823(
    name: "listFunctionEventInvokeConfigs", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config/list",
    validator: validate_ListFunctionEventInvokeConfigs_613824, base: "/",
    url: url_ListFunctionEventInvokeConfigs_613825,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctions_613840 = ref object of OpenApiRestCall_612658
proc url_ListFunctions_613842(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFunctions_613841(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of Lambda functions, with the version-specific configuration of each.</p> <p>Set <code>FunctionVersion</code> to <code>ALL</code> to include all published versions of each function in addition to the unpublished version. To get more information about a function or version, use <a>GetFunction</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   FunctionVersion: JString
  ##                  : Set to <code>ALL</code> to include entries for all published versions of each function.
  ##   MaxItems: JInt
  ##           : Specify a value between 1 and 50 to limit the number of functions in the response.
  ##   MasterRegion: JString
  ##               : For Lambda@Edge functions, the AWS Region of the master function. For example, <code>us-east-1</code> filters the list of functions to only include Lambda@Edge functions replicated from a master function in US East (N. Virginia). If specified, you must set <code>FunctionVersion</code> to <code>ALL</code>.
  section = newJObject()
  var valid_613843 = query.getOrDefault("Marker")
  valid_613843 = validateParameter(valid_613843, JString, required = false,
                                 default = nil)
  if valid_613843 != nil:
    section.add "Marker", valid_613843
  var valid_613844 = query.getOrDefault("FunctionVersion")
  valid_613844 = validateParameter(valid_613844, JString, required = false,
                                 default = newJString("ALL"))
  if valid_613844 != nil:
    section.add "FunctionVersion", valid_613844
  var valid_613845 = query.getOrDefault("MaxItems")
  valid_613845 = validateParameter(valid_613845, JInt, required = false, default = nil)
  if valid_613845 != nil:
    section.add "MaxItems", valid_613845
  var valid_613846 = query.getOrDefault("MasterRegion")
  valid_613846 = validateParameter(valid_613846, JString, required = false,
                                 default = nil)
  if valid_613846 != nil:
    section.add "MasterRegion", valid_613846
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613847 = header.getOrDefault("X-Amz-Signature")
  valid_613847 = validateParameter(valid_613847, JString, required = false,
                                 default = nil)
  if valid_613847 != nil:
    section.add "X-Amz-Signature", valid_613847
  var valid_613848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "X-Amz-Content-Sha256", valid_613848
  var valid_613849 = header.getOrDefault("X-Amz-Date")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "X-Amz-Date", valid_613849
  var valid_613850 = header.getOrDefault("X-Amz-Credential")
  valid_613850 = validateParameter(valid_613850, JString, required = false,
                                 default = nil)
  if valid_613850 != nil:
    section.add "X-Amz-Credential", valid_613850
  var valid_613851 = header.getOrDefault("X-Amz-Security-Token")
  valid_613851 = validateParameter(valid_613851, JString, required = false,
                                 default = nil)
  if valid_613851 != nil:
    section.add "X-Amz-Security-Token", valid_613851
  var valid_613852 = header.getOrDefault("X-Amz-Algorithm")
  valid_613852 = validateParameter(valid_613852, JString, required = false,
                                 default = nil)
  if valid_613852 != nil:
    section.add "X-Amz-Algorithm", valid_613852
  var valid_613853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613853 = validateParameter(valid_613853, JString, required = false,
                                 default = nil)
  if valid_613853 != nil:
    section.add "X-Amz-SignedHeaders", valid_613853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613854: Call_ListFunctions_613840; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of Lambda functions, with the version-specific configuration of each.</p> <p>Set <code>FunctionVersion</code> to <code>ALL</code> to include all published versions of each function in addition to the unpublished version. To get more information about a function or version, use <a>GetFunction</a>.</p>
  ## 
  let valid = call_613854.validator(path, query, header, formData, body)
  let scheme = call_613854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613854.url(scheme.get, call_613854.host, call_613854.base,
                         call_613854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613854, url, valid)

proc call*(call_613855: Call_ListFunctions_613840; Marker: string = "";
          FunctionVersion: string = "ALL"; MaxItems: int = 0; MasterRegion: string = ""): Recallable =
  ## listFunctions
  ## <p>Returns a list of Lambda functions, with the version-specific configuration of each.</p> <p>Set <code>FunctionVersion</code> to <code>ALL</code> to include all published versions of each function in addition to the unpublished version. To get more information about a function or version, use <a>GetFunction</a>.</p>
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   FunctionVersion: string
  ##                  : Set to <code>ALL</code> to include entries for all published versions of each function.
  ##   MaxItems: int
  ##           : Specify a value between 1 and 50 to limit the number of functions in the response.
  ##   MasterRegion: string
  ##               : For Lambda@Edge functions, the AWS Region of the master function. For example, <code>us-east-1</code> filters the list of functions to only include Lambda@Edge functions replicated from a master function in US East (N. Virginia). If specified, you must set <code>FunctionVersion</code> to <code>ALL</code>.
  var query_613856 = newJObject()
  add(query_613856, "Marker", newJString(Marker))
  add(query_613856, "FunctionVersion", newJString(FunctionVersion))
  add(query_613856, "MaxItems", newJInt(MaxItems))
  add(query_613856, "MasterRegion", newJString(MasterRegion))
  result = call_613855.call(nil, query_613856, nil, nil, nil)

var listFunctions* = Call_ListFunctions_613840(name: "listFunctions",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/", validator: validate_ListFunctions_613841,
    base: "/", url: url_ListFunctions_613842, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishLayerVersion_613875 = ref object of OpenApiRestCall_612658
proc url_PublishLayerVersion_613877(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PublishLayerVersion_613876(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a> from a ZIP archive. Each time you call <code>PublishLayerVersion</code> with the same layer name, a new version is created.</p> <p>Add layers to your function with <a>CreateFunction</a> or <a>UpdateFunctionConfiguration</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `LayerName` field"
  var valid_613878 = path.getOrDefault("LayerName")
  valid_613878 = validateParameter(valid_613878, JString, required = true,
                                 default = nil)
  if valid_613878 != nil:
    section.add "LayerName", valid_613878
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613879 = header.getOrDefault("X-Amz-Signature")
  valid_613879 = validateParameter(valid_613879, JString, required = false,
                                 default = nil)
  if valid_613879 != nil:
    section.add "X-Amz-Signature", valid_613879
  var valid_613880 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613880 = validateParameter(valid_613880, JString, required = false,
                                 default = nil)
  if valid_613880 != nil:
    section.add "X-Amz-Content-Sha256", valid_613880
  var valid_613881 = header.getOrDefault("X-Amz-Date")
  valid_613881 = validateParameter(valid_613881, JString, required = false,
                                 default = nil)
  if valid_613881 != nil:
    section.add "X-Amz-Date", valid_613881
  var valid_613882 = header.getOrDefault("X-Amz-Credential")
  valid_613882 = validateParameter(valid_613882, JString, required = false,
                                 default = nil)
  if valid_613882 != nil:
    section.add "X-Amz-Credential", valid_613882
  var valid_613883 = header.getOrDefault("X-Amz-Security-Token")
  valid_613883 = validateParameter(valid_613883, JString, required = false,
                                 default = nil)
  if valid_613883 != nil:
    section.add "X-Amz-Security-Token", valid_613883
  var valid_613884 = header.getOrDefault("X-Amz-Algorithm")
  valid_613884 = validateParameter(valid_613884, JString, required = false,
                                 default = nil)
  if valid_613884 != nil:
    section.add "X-Amz-Algorithm", valid_613884
  var valid_613885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613885 = validateParameter(valid_613885, JString, required = false,
                                 default = nil)
  if valid_613885 != nil:
    section.add "X-Amz-SignedHeaders", valid_613885
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613887: Call_PublishLayerVersion_613875; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a> from a ZIP archive. Each time you call <code>PublishLayerVersion</code> with the same layer name, a new version is created.</p> <p>Add layers to your function with <a>CreateFunction</a> or <a>UpdateFunctionConfiguration</a>.</p>
  ## 
  let valid = call_613887.validator(path, query, header, formData, body)
  let scheme = call_613887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613887.url(scheme.get, call_613887.host, call_613887.base,
                         call_613887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613887, url, valid)

proc call*(call_613888: Call_PublishLayerVersion_613875; LayerName: string;
          body: JsonNode): Recallable =
  ## publishLayerVersion
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a> from a ZIP archive. Each time you call <code>PublishLayerVersion</code> with the same layer name, a new version is created.</p> <p>Add layers to your function with <a>CreateFunction</a> or <a>UpdateFunctionConfiguration</a>.</p>
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   body: JObject (required)
  var path_613889 = newJObject()
  var body_613890 = newJObject()
  add(path_613889, "LayerName", newJString(LayerName))
  if body != nil:
    body_613890 = body
  result = call_613888.call(path_613889, nil, nil, nil, body_613890)

var publishLayerVersion* = Call_PublishLayerVersion_613875(
    name: "publishLayerVersion", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions",
    validator: validate_PublishLayerVersion_613876, base: "/",
    url: url_PublishLayerVersion_613877, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLayerVersions_613857 = ref object of OpenApiRestCall_612658
proc url_ListLayerVersions_613859(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListLayerVersions_613858(path: JsonNode; query: JsonNode;
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
  var valid_613860 = path.getOrDefault("LayerName")
  valid_613860 = validateParameter(valid_613860, JString, required = true,
                                 default = nil)
  if valid_613860 != nil:
    section.add "LayerName", valid_613860
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : A pagination token returned by a previous call.
  ##   CompatibleRuntime: JString
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   MaxItems: JInt
  ##           : The maximum number of versions to return.
  section = newJObject()
  var valid_613861 = query.getOrDefault("Marker")
  valid_613861 = validateParameter(valid_613861, JString, required = false,
                                 default = nil)
  if valid_613861 != nil:
    section.add "Marker", valid_613861
  var valid_613862 = query.getOrDefault("CompatibleRuntime")
  valid_613862 = validateParameter(valid_613862, JString, required = false,
                                 default = newJString("nodejs"))
  if valid_613862 != nil:
    section.add "CompatibleRuntime", valid_613862
  var valid_613863 = query.getOrDefault("MaxItems")
  valid_613863 = validateParameter(valid_613863, JInt, required = false, default = nil)
  if valid_613863 != nil:
    section.add "MaxItems", valid_613863
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613864 = header.getOrDefault("X-Amz-Signature")
  valid_613864 = validateParameter(valid_613864, JString, required = false,
                                 default = nil)
  if valid_613864 != nil:
    section.add "X-Amz-Signature", valid_613864
  var valid_613865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613865 = validateParameter(valid_613865, JString, required = false,
                                 default = nil)
  if valid_613865 != nil:
    section.add "X-Amz-Content-Sha256", valid_613865
  var valid_613866 = header.getOrDefault("X-Amz-Date")
  valid_613866 = validateParameter(valid_613866, JString, required = false,
                                 default = nil)
  if valid_613866 != nil:
    section.add "X-Amz-Date", valid_613866
  var valid_613867 = header.getOrDefault("X-Amz-Credential")
  valid_613867 = validateParameter(valid_613867, JString, required = false,
                                 default = nil)
  if valid_613867 != nil:
    section.add "X-Amz-Credential", valid_613867
  var valid_613868 = header.getOrDefault("X-Amz-Security-Token")
  valid_613868 = validateParameter(valid_613868, JString, required = false,
                                 default = nil)
  if valid_613868 != nil:
    section.add "X-Amz-Security-Token", valid_613868
  var valid_613869 = header.getOrDefault("X-Amz-Algorithm")
  valid_613869 = validateParameter(valid_613869, JString, required = false,
                                 default = nil)
  if valid_613869 != nil:
    section.add "X-Amz-Algorithm", valid_613869
  var valid_613870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613870 = validateParameter(valid_613870, JString, required = false,
                                 default = nil)
  if valid_613870 != nil:
    section.add "X-Amz-SignedHeaders", valid_613870
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613871: Call_ListLayerVersions_613857; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Versions that have been deleted aren't listed. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only versions that indicate that they're compatible with that runtime.
  ## 
  let valid = call_613871.validator(path, query, header, formData, body)
  let scheme = call_613871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613871.url(scheme.get, call_613871.host, call_613871.base,
                         call_613871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613871, url, valid)

proc call*(call_613872: Call_ListLayerVersions_613857; LayerName: string;
          Marker: string = ""; CompatibleRuntime: string = "nodejs"; MaxItems: int = 0): Recallable =
  ## listLayerVersions
  ## Lists the versions of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Versions that have been deleted aren't listed. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only versions that indicate that they're compatible with that runtime.
  ##   Marker: string
  ##         : A pagination token returned by a previous call.
  ##   CompatibleRuntime: string
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   MaxItems: int
  ##           : The maximum number of versions to return.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_613873 = newJObject()
  var query_613874 = newJObject()
  add(query_613874, "Marker", newJString(Marker))
  add(query_613874, "CompatibleRuntime", newJString(CompatibleRuntime))
  add(query_613874, "MaxItems", newJInt(MaxItems))
  add(path_613873, "LayerName", newJString(LayerName))
  result = call_613872.call(path_613873, query_613874, nil, nil, nil)

var listLayerVersions* = Call_ListLayerVersions_613857(name: "listLayerVersions",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions",
    validator: validate_ListLayerVersions_613858, base: "/",
    url: url_ListLayerVersions_613859, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLayers_613891 = ref object of OpenApiRestCall_612658
proc url_ListLayers_613893(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLayers_613892(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layers</a> and shows information about the latest version of each. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only layers that indicate that they're compatible with that runtime.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : A pagination token returned by a previous call.
  ##   CompatibleRuntime: JString
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   MaxItems: JInt
  ##           : The maximum number of layers to return.
  section = newJObject()
  var valid_613894 = query.getOrDefault("Marker")
  valid_613894 = validateParameter(valid_613894, JString, required = false,
                                 default = nil)
  if valid_613894 != nil:
    section.add "Marker", valid_613894
  var valid_613895 = query.getOrDefault("CompatibleRuntime")
  valid_613895 = validateParameter(valid_613895, JString, required = false,
                                 default = newJString("nodejs"))
  if valid_613895 != nil:
    section.add "CompatibleRuntime", valid_613895
  var valid_613896 = query.getOrDefault("MaxItems")
  valid_613896 = validateParameter(valid_613896, JInt, required = false, default = nil)
  if valid_613896 != nil:
    section.add "MaxItems", valid_613896
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613897 = header.getOrDefault("X-Amz-Signature")
  valid_613897 = validateParameter(valid_613897, JString, required = false,
                                 default = nil)
  if valid_613897 != nil:
    section.add "X-Amz-Signature", valid_613897
  var valid_613898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613898 = validateParameter(valid_613898, JString, required = false,
                                 default = nil)
  if valid_613898 != nil:
    section.add "X-Amz-Content-Sha256", valid_613898
  var valid_613899 = header.getOrDefault("X-Amz-Date")
  valid_613899 = validateParameter(valid_613899, JString, required = false,
                                 default = nil)
  if valid_613899 != nil:
    section.add "X-Amz-Date", valid_613899
  var valid_613900 = header.getOrDefault("X-Amz-Credential")
  valid_613900 = validateParameter(valid_613900, JString, required = false,
                                 default = nil)
  if valid_613900 != nil:
    section.add "X-Amz-Credential", valid_613900
  var valid_613901 = header.getOrDefault("X-Amz-Security-Token")
  valid_613901 = validateParameter(valid_613901, JString, required = false,
                                 default = nil)
  if valid_613901 != nil:
    section.add "X-Amz-Security-Token", valid_613901
  var valid_613902 = header.getOrDefault("X-Amz-Algorithm")
  valid_613902 = validateParameter(valid_613902, JString, required = false,
                                 default = nil)
  if valid_613902 != nil:
    section.add "X-Amz-Algorithm", valid_613902
  var valid_613903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613903 = validateParameter(valid_613903, JString, required = false,
                                 default = nil)
  if valid_613903 != nil:
    section.add "X-Amz-SignedHeaders", valid_613903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613904: Call_ListLayers_613891; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layers</a> and shows information about the latest version of each. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only layers that indicate that they're compatible with that runtime.
  ## 
  let valid = call_613904.validator(path, query, header, formData, body)
  let scheme = call_613904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613904.url(scheme.get, call_613904.host, call_613904.base,
                         call_613904.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613904, url, valid)

proc call*(call_613905: Call_ListLayers_613891; Marker: string = "";
          CompatibleRuntime: string = "nodejs"; MaxItems: int = 0): Recallable =
  ## listLayers
  ## Lists <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layers</a> and shows information about the latest version of each. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only layers that indicate that they're compatible with that runtime.
  ##   Marker: string
  ##         : A pagination token returned by a previous call.
  ##   CompatibleRuntime: string
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   MaxItems: int
  ##           : The maximum number of layers to return.
  var query_613906 = newJObject()
  add(query_613906, "Marker", newJString(Marker))
  add(query_613906, "CompatibleRuntime", newJString(CompatibleRuntime))
  add(query_613906, "MaxItems", newJInt(MaxItems))
  result = call_613905.call(nil, query_613906, nil, nil, nil)

var listLayers* = Call_ListLayers_613891(name: "listLayers",
                                      meth: HttpMethod.HttpGet,
                                      host: "lambda.amazonaws.com",
                                      route: "/2018-10-31/layers",
                                      validator: validate_ListLayers_613892,
                                      base: "/", url: url_ListLayers_613893,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisionedConcurrencyConfigs_613907 = ref object of OpenApiRestCall_612658
proc url_ListProvisionedConcurrencyConfigs_613909(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-09-30/functions/"),
               (kind: VariableSegment, value: "FunctionName"), (
        kind: ConstantSegment, value: "/provisioned-concurrency#List=ALL")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListProvisionedConcurrencyConfigs_613908(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of provisioned concurrency configurations for a function.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_613910 = path.getOrDefault("FunctionName")
  valid_613910 = validateParameter(valid_613910, JString, required = true,
                                 default = nil)
  if valid_613910 != nil:
    section.add "FunctionName", valid_613910
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : Specify a number to limit the number of configurations returned.
  ##   List: JString (required)
  section = newJObject()
  var valid_613911 = query.getOrDefault("Marker")
  valid_613911 = validateParameter(valid_613911, JString, required = false,
                                 default = nil)
  if valid_613911 != nil:
    section.add "Marker", valid_613911
  var valid_613912 = query.getOrDefault("MaxItems")
  valid_613912 = validateParameter(valid_613912, JInt, required = false, default = nil)
  if valid_613912 != nil:
    section.add "MaxItems", valid_613912
  var valid_613913 = query.getOrDefault("List")
  valid_613913 = validateParameter(valid_613913, JString, required = true,
                                 default = newJString("ALL"))
  if valid_613913 != nil:
    section.add "List", valid_613913
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613914 = header.getOrDefault("X-Amz-Signature")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "X-Amz-Signature", valid_613914
  var valid_613915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613915 = validateParameter(valid_613915, JString, required = false,
                                 default = nil)
  if valid_613915 != nil:
    section.add "X-Amz-Content-Sha256", valid_613915
  var valid_613916 = header.getOrDefault("X-Amz-Date")
  valid_613916 = validateParameter(valid_613916, JString, required = false,
                                 default = nil)
  if valid_613916 != nil:
    section.add "X-Amz-Date", valid_613916
  var valid_613917 = header.getOrDefault("X-Amz-Credential")
  valid_613917 = validateParameter(valid_613917, JString, required = false,
                                 default = nil)
  if valid_613917 != nil:
    section.add "X-Amz-Credential", valid_613917
  var valid_613918 = header.getOrDefault("X-Amz-Security-Token")
  valid_613918 = validateParameter(valid_613918, JString, required = false,
                                 default = nil)
  if valid_613918 != nil:
    section.add "X-Amz-Security-Token", valid_613918
  var valid_613919 = header.getOrDefault("X-Amz-Algorithm")
  valid_613919 = validateParameter(valid_613919, JString, required = false,
                                 default = nil)
  if valid_613919 != nil:
    section.add "X-Amz-Algorithm", valid_613919
  var valid_613920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613920 = validateParameter(valid_613920, JString, required = false,
                                 default = nil)
  if valid_613920 != nil:
    section.add "X-Amz-SignedHeaders", valid_613920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613921: Call_ListProvisionedConcurrencyConfigs_613907;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves a list of provisioned concurrency configurations for a function.
  ## 
  let valid = call_613921.validator(path, query, header, formData, body)
  let scheme = call_613921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613921.url(scheme.get, call_613921.host, call_613921.base,
                         call_613921.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613921, url, valid)

proc call*(call_613922: Call_ListProvisionedConcurrencyConfigs_613907;
          FunctionName: string; Marker: string = ""; MaxItems: int = 0;
          List: string = "ALL"): Recallable =
  ## listProvisionedConcurrencyConfigs
  ## Retrieves a list of provisioned concurrency configurations for a function.
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   MaxItems: int
  ##           : Specify a number to limit the number of configurations returned.
  ##   List: string (required)
  var path_613923 = newJObject()
  var query_613924 = newJObject()
  add(query_613924, "Marker", newJString(Marker))
  add(path_613923, "FunctionName", newJString(FunctionName))
  add(query_613924, "MaxItems", newJInt(MaxItems))
  add(query_613924, "List", newJString(List))
  result = call_613922.call(path_613923, query_613924, nil, nil, nil)

var listProvisionedConcurrencyConfigs* = Call_ListProvisionedConcurrencyConfigs_613907(
    name: "listProvisionedConcurrencyConfigs", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#List=ALL",
    validator: validate_ListProvisionedConcurrencyConfigs_613908, base: "/",
    url: url_ListProvisionedConcurrencyConfigs_613909,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613939 = ref object of OpenApiRestCall_612658
proc url_TagResource_613941(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_613940(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613942 = path.getOrDefault("ARN")
  valid_613942 = validateParameter(valid_613942, JString, required = true,
                                 default = nil)
  if valid_613942 != nil:
    section.add "ARN", valid_613942
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613943 = header.getOrDefault("X-Amz-Signature")
  valid_613943 = validateParameter(valid_613943, JString, required = false,
                                 default = nil)
  if valid_613943 != nil:
    section.add "X-Amz-Signature", valid_613943
  var valid_613944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613944 = validateParameter(valid_613944, JString, required = false,
                                 default = nil)
  if valid_613944 != nil:
    section.add "X-Amz-Content-Sha256", valid_613944
  var valid_613945 = header.getOrDefault("X-Amz-Date")
  valid_613945 = validateParameter(valid_613945, JString, required = false,
                                 default = nil)
  if valid_613945 != nil:
    section.add "X-Amz-Date", valid_613945
  var valid_613946 = header.getOrDefault("X-Amz-Credential")
  valid_613946 = validateParameter(valid_613946, JString, required = false,
                                 default = nil)
  if valid_613946 != nil:
    section.add "X-Amz-Credential", valid_613946
  var valid_613947 = header.getOrDefault("X-Amz-Security-Token")
  valid_613947 = validateParameter(valid_613947, JString, required = false,
                                 default = nil)
  if valid_613947 != nil:
    section.add "X-Amz-Security-Token", valid_613947
  var valid_613948 = header.getOrDefault("X-Amz-Algorithm")
  valid_613948 = validateParameter(valid_613948, JString, required = false,
                                 default = nil)
  if valid_613948 != nil:
    section.add "X-Amz-Algorithm", valid_613948
  var valid_613949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613949 = validateParameter(valid_613949, JString, required = false,
                                 default = nil)
  if valid_613949 != nil:
    section.add "X-Amz-SignedHeaders", valid_613949
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613951: Call_TagResource_613939; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> to a function.
  ## 
  let valid = call_613951.validator(path, query, header, formData, body)
  let scheme = call_613951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613951.url(scheme.get, call_613951.host, call_613951.base,
                         call_613951.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613951, url, valid)

proc call*(call_613952: Call_TagResource_613939; ARN: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> to a function.
  ##   ARN: string (required)
  ##      : The function's Amazon Resource Name (ARN).
  ##   body: JObject (required)
  var path_613953 = newJObject()
  var body_613954 = newJObject()
  add(path_613953, "ARN", newJString(ARN))
  if body != nil:
    body_613954 = body
  result = call_613952.call(path_613953, nil, nil, nil, body_613954)

var tagResource* = Call_TagResource_613939(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com",
                                        route: "/2017-03-31/tags/{ARN}",
                                        validator: validate_TagResource_613940,
                                        base: "/", url: url_TagResource_613941,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_613925 = ref object of OpenApiRestCall_612658
proc url_ListTags_613927(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTags_613926(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613928 = path.getOrDefault("ARN")
  valid_613928 = validateParameter(valid_613928, JString, required = true,
                                 default = nil)
  if valid_613928 != nil:
    section.add "ARN", valid_613928
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613929 = header.getOrDefault("X-Amz-Signature")
  valid_613929 = validateParameter(valid_613929, JString, required = false,
                                 default = nil)
  if valid_613929 != nil:
    section.add "X-Amz-Signature", valid_613929
  var valid_613930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613930 = validateParameter(valid_613930, JString, required = false,
                                 default = nil)
  if valid_613930 != nil:
    section.add "X-Amz-Content-Sha256", valid_613930
  var valid_613931 = header.getOrDefault("X-Amz-Date")
  valid_613931 = validateParameter(valid_613931, JString, required = false,
                                 default = nil)
  if valid_613931 != nil:
    section.add "X-Amz-Date", valid_613931
  var valid_613932 = header.getOrDefault("X-Amz-Credential")
  valid_613932 = validateParameter(valid_613932, JString, required = false,
                                 default = nil)
  if valid_613932 != nil:
    section.add "X-Amz-Credential", valid_613932
  var valid_613933 = header.getOrDefault("X-Amz-Security-Token")
  valid_613933 = validateParameter(valid_613933, JString, required = false,
                                 default = nil)
  if valid_613933 != nil:
    section.add "X-Amz-Security-Token", valid_613933
  var valid_613934 = header.getOrDefault("X-Amz-Algorithm")
  valid_613934 = validateParameter(valid_613934, JString, required = false,
                                 default = nil)
  if valid_613934 != nil:
    section.add "X-Amz-Algorithm", valid_613934
  var valid_613935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613935 = validateParameter(valid_613935, JString, required = false,
                                 default = nil)
  if valid_613935 != nil:
    section.add "X-Amz-SignedHeaders", valid_613935
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613936: Call_ListTags_613925; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a>. You can also view tags with <a>GetFunction</a>.
  ## 
  let valid = call_613936.validator(path, query, header, formData, body)
  let scheme = call_613936.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613936.url(scheme.get, call_613936.host, call_613936.base,
                         call_613936.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613936, url, valid)

proc call*(call_613937: Call_ListTags_613925; ARN: string): Recallable =
  ## listTags
  ## Returns a function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a>. You can also view tags with <a>GetFunction</a>.
  ##   ARN: string (required)
  ##      : The function's Amazon Resource Name (ARN).
  var path_613938 = newJObject()
  add(path_613938, "ARN", newJString(ARN))
  result = call_613937.call(path_613938, nil, nil, nil, nil)

var listTags* = Call_ListTags_613925(name: "listTags", meth: HttpMethod.HttpGet,
                                  host: "lambda.amazonaws.com",
                                  route: "/2017-03-31/tags/{ARN}",
                                  validator: validate_ListTags_613926, base: "/",
                                  url: url_ListTags_613927,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishVersion_613972 = ref object of OpenApiRestCall_612658
proc url_PublishVersion_613974(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PublishVersion_613973(path: JsonNode; query: JsonNode;
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
  var valid_613975 = path.getOrDefault("FunctionName")
  valid_613975 = validateParameter(valid_613975, JString, required = true,
                                 default = nil)
  if valid_613975 != nil:
    section.add "FunctionName", valid_613975
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613976 = header.getOrDefault("X-Amz-Signature")
  valid_613976 = validateParameter(valid_613976, JString, required = false,
                                 default = nil)
  if valid_613976 != nil:
    section.add "X-Amz-Signature", valid_613976
  var valid_613977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613977 = validateParameter(valid_613977, JString, required = false,
                                 default = nil)
  if valid_613977 != nil:
    section.add "X-Amz-Content-Sha256", valid_613977
  var valid_613978 = header.getOrDefault("X-Amz-Date")
  valid_613978 = validateParameter(valid_613978, JString, required = false,
                                 default = nil)
  if valid_613978 != nil:
    section.add "X-Amz-Date", valid_613978
  var valid_613979 = header.getOrDefault("X-Amz-Credential")
  valid_613979 = validateParameter(valid_613979, JString, required = false,
                                 default = nil)
  if valid_613979 != nil:
    section.add "X-Amz-Credential", valid_613979
  var valid_613980 = header.getOrDefault("X-Amz-Security-Token")
  valid_613980 = validateParameter(valid_613980, JString, required = false,
                                 default = nil)
  if valid_613980 != nil:
    section.add "X-Amz-Security-Token", valid_613980
  var valid_613981 = header.getOrDefault("X-Amz-Algorithm")
  valid_613981 = validateParameter(valid_613981, JString, required = false,
                                 default = nil)
  if valid_613981 != nil:
    section.add "X-Amz-Algorithm", valid_613981
  var valid_613982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613982 = validateParameter(valid_613982, JString, required = false,
                                 default = nil)
  if valid_613982 != nil:
    section.add "X-Amz-SignedHeaders", valid_613982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613984: Call_PublishVersion_613972; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">version</a> from the current code and configuration of a function. Use versions to create a snapshot of your function code and configuration that doesn't change.</p> <p>AWS Lambda doesn't publish a version if the function's configuration and code haven't changed since the last version. Use <a>UpdateFunctionCode</a> or <a>UpdateFunctionConfiguration</a> to update the function before publishing a version.</p> <p>Clients can invoke versions directly or with an alias. To create an alias, use <a>CreateAlias</a>.</p>
  ## 
  let valid = call_613984.validator(path, query, header, formData, body)
  let scheme = call_613984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613984.url(scheme.get, call_613984.host, call_613984.base,
                         call_613984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613984, url, valid)

proc call*(call_613985: Call_PublishVersion_613972; FunctionName: string;
          body: JsonNode): Recallable =
  ## publishVersion
  ## <p>Creates a <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">version</a> from the current code and configuration of a function. Use versions to create a snapshot of your function code and configuration that doesn't change.</p> <p>AWS Lambda doesn't publish a version if the function's configuration and code haven't changed since the last version. Use <a>UpdateFunctionCode</a> or <a>UpdateFunctionConfiguration</a> to update the function before publishing a version.</p> <p>Clients can invoke versions directly or with an alias. To create an alias, use <a>CreateAlias</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_613986 = newJObject()
  var body_613987 = newJObject()
  add(path_613986, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_613987 = body
  result = call_613985.call(path_613986, nil, nil, nil, body_613987)

var publishVersion* = Call_PublishVersion_613972(name: "publishVersion",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/versions",
    validator: validate_PublishVersion_613973, base: "/", url: url_PublishVersion_613974,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVersionsByFunction_613955 = ref object of OpenApiRestCall_612658
proc url_ListVersionsByFunction_613957(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListVersionsByFunction_613956(path: JsonNode; query: JsonNode;
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
  var valid_613958 = path.getOrDefault("FunctionName")
  valid_613958 = validateParameter(valid_613958, JString, required = true,
                                 default = nil)
  if valid_613958 != nil:
    section.add "FunctionName", valid_613958
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : Limit the number of versions that are returned.
  section = newJObject()
  var valid_613959 = query.getOrDefault("Marker")
  valid_613959 = validateParameter(valid_613959, JString, required = false,
                                 default = nil)
  if valid_613959 != nil:
    section.add "Marker", valid_613959
  var valid_613960 = query.getOrDefault("MaxItems")
  valid_613960 = validateParameter(valid_613960, JInt, required = false, default = nil)
  if valid_613960 != nil:
    section.add "MaxItems", valid_613960
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613961 = header.getOrDefault("X-Amz-Signature")
  valid_613961 = validateParameter(valid_613961, JString, required = false,
                                 default = nil)
  if valid_613961 != nil:
    section.add "X-Amz-Signature", valid_613961
  var valid_613962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613962 = validateParameter(valid_613962, JString, required = false,
                                 default = nil)
  if valid_613962 != nil:
    section.add "X-Amz-Content-Sha256", valid_613962
  var valid_613963 = header.getOrDefault("X-Amz-Date")
  valid_613963 = validateParameter(valid_613963, JString, required = false,
                                 default = nil)
  if valid_613963 != nil:
    section.add "X-Amz-Date", valid_613963
  var valid_613964 = header.getOrDefault("X-Amz-Credential")
  valid_613964 = validateParameter(valid_613964, JString, required = false,
                                 default = nil)
  if valid_613964 != nil:
    section.add "X-Amz-Credential", valid_613964
  var valid_613965 = header.getOrDefault("X-Amz-Security-Token")
  valid_613965 = validateParameter(valid_613965, JString, required = false,
                                 default = nil)
  if valid_613965 != nil:
    section.add "X-Amz-Security-Token", valid_613965
  var valid_613966 = header.getOrDefault("X-Amz-Algorithm")
  valid_613966 = validateParameter(valid_613966, JString, required = false,
                                 default = nil)
  if valid_613966 != nil:
    section.add "X-Amz-Algorithm", valid_613966
  var valid_613967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613967 = validateParameter(valid_613967, JString, required = false,
                                 default = nil)
  if valid_613967 != nil:
    section.add "X-Amz-SignedHeaders", valid_613967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613968: Call_ListVersionsByFunction_613955; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">versions</a>, with the version-specific configuration of each. 
  ## 
  let valid = call_613968.validator(path, query, header, formData, body)
  let scheme = call_613968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613968.url(scheme.get, call_613968.host, call_613968.base,
                         call_613968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613968, url, valid)

proc call*(call_613969: Call_ListVersionsByFunction_613955; FunctionName: string;
          Marker: string = ""; MaxItems: int = 0): Recallable =
  ## listVersionsByFunction
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">versions</a>, with the version-specific configuration of each. 
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   MaxItems: int
  ##           : Limit the number of versions that are returned.
  var path_613970 = newJObject()
  var query_613971 = newJObject()
  add(query_613971, "Marker", newJString(Marker))
  add(path_613970, "FunctionName", newJString(FunctionName))
  add(query_613971, "MaxItems", newJInt(MaxItems))
  result = call_613969.call(path_613970, query_613971, nil, nil, nil)

var listVersionsByFunction* = Call_ListVersionsByFunction_613955(
    name: "listVersionsByFunction", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/versions",
    validator: validate_ListVersionsByFunction_613956, base: "/",
    url: url_ListVersionsByFunction_613957, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveLayerVersionPermission_613988 = ref object of OpenApiRestCall_612658
proc url_RemoveLayerVersionPermission_613990(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RemoveLayerVersionPermission_613989(path: JsonNode; query: JsonNode;
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
  var valid_613991 = path.getOrDefault("VersionNumber")
  valid_613991 = validateParameter(valid_613991, JInt, required = true, default = nil)
  if valid_613991 != nil:
    section.add "VersionNumber", valid_613991
  var valid_613992 = path.getOrDefault("StatementId")
  valid_613992 = validateParameter(valid_613992, JString, required = true,
                                 default = nil)
  if valid_613992 != nil:
    section.add "StatementId", valid_613992
  var valid_613993 = path.getOrDefault("LayerName")
  valid_613993 = validateParameter(valid_613993, JString, required = true,
                                 default = nil)
  if valid_613993 != nil:
    section.add "LayerName", valid_613993
  result.add "path", section
  ## parameters in `query` object:
  ##   RevisionId: JString
  ##             : Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  section = newJObject()
  var valid_613994 = query.getOrDefault("RevisionId")
  valid_613994 = validateParameter(valid_613994, JString, required = false,
                                 default = nil)
  if valid_613994 != nil:
    section.add "RevisionId", valid_613994
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613995 = header.getOrDefault("X-Amz-Signature")
  valid_613995 = validateParameter(valid_613995, JString, required = false,
                                 default = nil)
  if valid_613995 != nil:
    section.add "X-Amz-Signature", valid_613995
  var valid_613996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613996 = validateParameter(valid_613996, JString, required = false,
                                 default = nil)
  if valid_613996 != nil:
    section.add "X-Amz-Content-Sha256", valid_613996
  var valid_613997 = header.getOrDefault("X-Amz-Date")
  valid_613997 = validateParameter(valid_613997, JString, required = false,
                                 default = nil)
  if valid_613997 != nil:
    section.add "X-Amz-Date", valid_613997
  var valid_613998 = header.getOrDefault("X-Amz-Credential")
  valid_613998 = validateParameter(valid_613998, JString, required = false,
                                 default = nil)
  if valid_613998 != nil:
    section.add "X-Amz-Credential", valid_613998
  var valid_613999 = header.getOrDefault("X-Amz-Security-Token")
  valid_613999 = validateParameter(valid_613999, JString, required = false,
                                 default = nil)
  if valid_613999 != nil:
    section.add "X-Amz-Security-Token", valid_613999
  var valid_614000 = header.getOrDefault("X-Amz-Algorithm")
  valid_614000 = validateParameter(valid_614000, JString, required = false,
                                 default = nil)
  if valid_614000 != nil:
    section.add "X-Amz-Algorithm", valid_614000
  var valid_614001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614001 = validateParameter(valid_614001, JString, required = false,
                                 default = nil)
  if valid_614001 != nil:
    section.add "X-Amz-SignedHeaders", valid_614001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614002: Call_RemoveLayerVersionPermission_613988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from the permissions policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ## 
  let valid = call_614002.validator(path, query, header, formData, body)
  let scheme = call_614002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614002.url(scheme.get, call_614002.host, call_614002.base,
                         call_614002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614002, url, valid)

proc call*(call_614003: Call_RemoveLayerVersionPermission_613988;
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
  var path_614004 = newJObject()
  var query_614005 = newJObject()
  add(query_614005, "RevisionId", newJString(RevisionId))
  add(path_614004, "VersionNumber", newJInt(VersionNumber))
  add(path_614004, "StatementId", newJString(StatementId))
  add(path_614004, "LayerName", newJString(LayerName))
  result = call_614003.call(path_614004, query_614005, nil, nil, nil)

var removeLayerVersionPermission* = Call_RemoveLayerVersionPermission_613988(
    name: "removeLayerVersionPermission", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com", route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy/{StatementId}",
    validator: validate_RemoveLayerVersionPermission_613989, base: "/",
    url: url_RemoveLayerVersionPermission_613990,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemovePermission_614006 = ref object of OpenApiRestCall_612658
proc url_RemovePermission_614008(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RemovePermission_614007(path: JsonNode; query: JsonNode;
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
  var valid_614009 = path.getOrDefault("FunctionName")
  valid_614009 = validateParameter(valid_614009, JString, required = true,
                                 default = nil)
  if valid_614009 != nil:
    section.add "FunctionName", valid_614009
  var valid_614010 = path.getOrDefault("StatementId")
  valid_614010 = validateParameter(valid_614010, JString, required = true,
                                 default = nil)
  if valid_614010 != nil:
    section.add "StatementId", valid_614010
  result.add "path", section
  ## parameters in `query` object:
  ##   RevisionId: JString
  ##             : Only update the policy if the revision ID matches the ID that's specified. Use this option to avoid modifying a policy that has changed since you last read it.
  ##   Qualifier: JString
  ##            : Specify a version or alias to remove permissions from a published version of the function.
  section = newJObject()
  var valid_614011 = query.getOrDefault("RevisionId")
  valid_614011 = validateParameter(valid_614011, JString, required = false,
                                 default = nil)
  if valid_614011 != nil:
    section.add "RevisionId", valid_614011
  var valid_614012 = query.getOrDefault("Qualifier")
  valid_614012 = validateParameter(valid_614012, JString, required = false,
                                 default = nil)
  if valid_614012 != nil:
    section.add "Qualifier", valid_614012
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614013 = header.getOrDefault("X-Amz-Signature")
  valid_614013 = validateParameter(valid_614013, JString, required = false,
                                 default = nil)
  if valid_614013 != nil:
    section.add "X-Amz-Signature", valid_614013
  var valid_614014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614014 = validateParameter(valid_614014, JString, required = false,
                                 default = nil)
  if valid_614014 != nil:
    section.add "X-Amz-Content-Sha256", valid_614014
  var valid_614015 = header.getOrDefault("X-Amz-Date")
  valid_614015 = validateParameter(valid_614015, JString, required = false,
                                 default = nil)
  if valid_614015 != nil:
    section.add "X-Amz-Date", valid_614015
  var valid_614016 = header.getOrDefault("X-Amz-Credential")
  valid_614016 = validateParameter(valid_614016, JString, required = false,
                                 default = nil)
  if valid_614016 != nil:
    section.add "X-Amz-Credential", valid_614016
  var valid_614017 = header.getOrDefault("X-Amz-Security-Token")
  valid_614017 = validateParameter(valid_614017, JString, required = false,
                                 default = nil)
  if valid_614017 != nil:
    section.add "X-Amz-Security-Token", valid_614017
  var valid_614018 = header.getOrDefault("X-Amz-Algorithm")
  valid_614018 = validateParameter(valid_614018, JString, required = false,
                                 default = nil)
  if valid_614018 != nil:
    section.add "X-Amz-Algorithm", valid_614018
  var valid_614019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614019 = validateParameter(valid_614019, JString, required = false,
                                 default = nil)
  if valid_614019 != nil:
    section.add "X-Amz-SignedHeaders", valid_614019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614020: Call_RemovePermission_614006; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes function-use permission from an AWS service or another account. You can get the ID of the statement from the output of <a>GetPolicy</a>.
  ## 
  let valid = call_614020.validator(path, query, header, formData, body)
  let scheme = call_614020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614020.url(scheme.get, call_614020.host, call_614020.base,
                         call_614020.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614020, url, valid)

proc call*(call_614021: Call_RemovePermission_614006; FunctionName: string;
          StatementId: string; RevisionId: string = ""; Qualifier: string = ""): Recallable =
  ## removePermission
  ## Revokes function-use permission from an AWS service or another account. You can get the ID of the statement from the output of <a>GetPolicy</a>.
  ##   RevisionId: string
  ##             : Only update the policy if the revision ID matches the ID that's specified. Use this option to avoid modifying a policy that has changed since you last read it.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   StatementId: string (required)
  ##              : Statement ID of the permission to remove.
  ##   Qualifier: string
  ##            : Specify a version or alias to remove permissions from a published version of the function.
  var path_614022 = newJObject()
  var query_614023 = newJObject()
  add(query_614023, "RevisionId", newJString(RevisionId))
  add(path_614022, "FunctionName", newJString(FunctionName))
  add(path_614022, "StatementId", newJString(StatementId))
  add(query_614023, "Qualifier", newJString(Qualifier))
  result = call_614021.call(path_614022, query_614023, nil, nil, nil)

var removePermission* = Call_RemovePermission_614006(name: "removePermission",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/policy/{StatementId}",
    validator: validate_RemovePermission_614007, base: "/",
    url: url_RemovePermission_614008, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_614024 = ref object of OpenApiRestCall_612658
proc url_UntagResource_614026(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_614025(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614027 = path.getOrDefault("ARN")
  valid_614027 = validateParameter(valid_614027, JString, required = true,
                                 default = nil)
  if valid_614027 != nil:
    section.add "ARN", valid_614027
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A list of tag keys to remove from the function.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_614028 = query.getOrDefault("tagKeys")
  valid_614028 = validateParameter(valid_614028, JArray, required = true, default = nil)
  if valid_614028 != nil:
    section.add "tagKeys", valid_614028
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614029 = header.getOrDefault("X-Amz-Signature")
  valid_614029 = validateParameter(valid_614029, JString, required = false,
                                 default = nil)
  if valid_614029 != nil:
    section.add "X-Amz-Signature", valid_614029
  var valid_614030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614030 = validateParameter(valid_614030, JString, required = false,
                                 default = nil)
  if valid_614030 != nil:
    section.add "X-Amz-Content-Sha256", valid_614030
  var valid_614031 = header.getOrDefault("X-Amz-Date")
  valid_614031 = validateParameter(valid_614031, JString, required = false,
                                 default = nil)
  if valid_614031 != nil:
    section.add "X-Amz-Date", valid_614031
  var valid_614032 = header.getOrDefault("X-Amz-Credential")
  valid_614032 = validateParameter(valid_614032, JString, required = false,
                                 default = nil)
  if valid_614032 != nil:
    section.add "X-Amz-Credential", valid_614032
  var valid_614033 = header.getOrDefault("X-Amz-Security-Token")
  valid_614033 = validateParameter(valid_614033, JString, required = false,
                                 default = nil)
  if valid_614033 != nil:
    section.add "X-Amz-Security-Token", valid_614033
  var valid_614034 = header.getOrDefault("X-Amz-Algorithm")
  valid_614034 = validateParameter(valid_614034, JString, required = false,
                                 default = nil)
  if valid_614034 != nil:
    section.add "X-Amz-Algorithm", valid_614034
  var valid_614035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614035 = validateParameter(valid_614035, JString, required = false,
                                 default = nil)
  if valid_614035 != nil:
    section.add "X-Amz-SignedHeaders", valid_614035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614036: Call_UntagResource_614024; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> from a function.
  ## 
  let valid = call_614036.validator(path, query, header, formData, body)
  let scheme = call_614036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614036.url(scheme.get, call_614036.host, call_614036.base,
                         call_614036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614036, url, valid)

proc call*(call_614037: Call_UntagResource_614024; ARN: string; tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> from a function.
  ##   ARN: string (required)
  ##      : The function's Amazon Resource Name (ARN).
  ##   tagKeys: JArray (required)
  ##          : A list of tag keys to remove from the function.
  var path_614038 = newJObject()
  var query_614039 = newJObject()
  add(path_614038, "ARN", newJString(ARN))
  if tagKeys != nil:
    query_614039.add "tagKeys", tagKeys
  result = call_614037.call(path_614038, query_614039, nil, nil, nil)

var untagResource* = Call_UntagResource_614024(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2017-03-31/tags/{ARN}#tagKeys", validator: validate_UntagResource_614025,
    base: "/", url: url_UntagResource_614026, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionCode_614040 = ref object of OpenApiRestCall_612658
proc url_UpdateFunctionCode_614042(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFunctionCode_614041(path: JsonNode; query: JsonNode;
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
  var valid_614043 = path.getOrDefault("FunctionName")
  valid_614043 = validateParameter(valid_614043, JString, required = true,
                                 default = nil)
  if valid_614043 != nil:
    section.add "FunctionName", valid_614043
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614044 = header.getOrDefault("X-Amz-Signature")
  valid_614044 = validateParameter(valid_614044, JString, required = false,
                                 default = nil)
  if valid_614044 != nil:
    section.add "X-Amz-Signature", valid_614044
  var valid_614045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614045 = validateParameter(valid_614045, JString, required = false,
                                 default = nil)
  if valid_614045 != nil:
    section.add "X-Amz-Content-Sha256", valid_614045
  var valid_614046 = header.getOrDefault("X-Amz-Date")
  valid_614046 = validateParameter(valid_614046, JString, required = false,
                                 default = nil)
  if valid_614046 != nil:
    section.add "X-Amz-Date", valid_614046
  var valid_614047 = header.getOrDefault("X-Amz-Credential")
  valid_614047 = validateParameter(valid_614047, JString, required = false,
                                 default = nil)
  if valid_614047 != nil:
    section.add "X-Amz-Credential", valid_614047
  var valid_614048 = header.getOrDefault("X-Amz-Security-Token")
  valid_614048 = validateParameter(valid_614048, JString, required = false,
                                 default = nil)
  if valid_614048 != nil:
    section.add "X-Amz-Security-Token", valid_614048
  var valid_614049 = header.getOrDefault("X-Amz-Algorithm")
  valid_614049 = validateParameter(valid_614049, JString, required = false,
                                 default = nil)
  if valid_614049 != nil:
    section.add "X-Amz-Algorithm", valid_614049
  var valid_614050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614050 = validateParameter(valid_614050, JString, required = false,
                                 default = nil)
  if valid_614050 != nil:
    section.add "X-Amz-SignedHeaders", valid_614050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614052: Call_UpdateFunctionCode_614040; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a Lambda function's code.</p> <p>The function's code is locked when you publish a version. You can't modify the code of a published version, only the unpublished version.</p>
  ## 
  let valid = call_614052.validator(path, query, header, formData, body)
  let scheme = call_614052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614052.url(scheme.get, call_614052.host, call_614052.base,
                         call_614052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614052, url, valid)

proc call*(call_614053: Call_UpdateFunctionCode_614040; FunctionName: string;
          body: JsonNode): Recallable =
  ## updateFunctionCode
  ## <p>Updates a Lambda function's code.</p> <p>The function's code is locked when you publish a version. You can't modify the code of a published version, only the unpublished version.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_614054 = newJObject()
  var body_614055 = newJObject()
  add(path_614054, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_614055 = body
  result = call_614053.call(path_614054, nil, nil, nil, body_614055)

var updateFunctionCode* = Call_UpdateFunctionCode_614040(
    name: "updateFunctionCode", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/code",
    validator: validate_UpdateFunctionCode_614041, base: "/",
    url: url_UpdateFunctionCode_614042, schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
