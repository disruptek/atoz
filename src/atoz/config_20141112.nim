
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Config
## version: 2014-11-12
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Config</fullname> <p>AWS Config provides a way to keep track of the configurations of all the AWS resources associated with your AWS account. You can use AWS Config to get the current and historical configurations of each AWS resource and also to get information about the relationship between the resources. An AWS resource can be an Amazon Compute Cloud (Amazon EC2) instance, an Elastic Block Store (EBS) volume, an elastic network Interface (ENI), or a security group. For a complete list of resources currently supported by AWS Config, see <a href="https://docs.aws.amazon.com/config/latest/developerguide/resource-config-reference.html#supported-resources">Supported AWS Resources</a>.</p> <p>You can access and manage AWS Config through the AWS Management Console, the AWS Command Line Interface (AWS CLI), the AWS Config API, or the AWS SDKs for AWS Config. This reference guide contains documentation for the AWS Config API and the AWS CLI commands that you can use to manage AWS Config. The AWS Config API uses the Signature Version 4 protocol for signing requests. For more information about how to sign a request with this protocol, see <a href="https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html">Signature Version 4 Signing Process</a>. For detailed information about AWS Config features and their associated actions or commands, as well as how to work with AWS Management Console, see <a href="https://docs.aws.amazon.com/config/latest/developerguide/WhatIsConfig.html">What Is AWS Config</a> in the <i>AWS Config Developer Guide</i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/config/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
  awsServers = {Scheme.Http: {"ap-northeast-1": "config.ap-northeast-1.amazonaws.com", "ap-southeast-1": "config.ap-southeast-1.amazonaws.com",
                           "us-west-2": "config.us-west-2.amazonaws.com",
                           "eu-west-2": "config.eu-west-2.amazonaws.com", "ap-northeast-3": "config.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "config.eu-central-1.amazonaws.com",
                           "us-east-2": "config.us-east-2.amazonaws.com",
                           "us-east-1": "config.us-east-1.amazonaws.com", "cn-northwest-1": "config.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "config.ap-south-1.amazonaws.com",
                           "eu-north-1": "config.eu-north-1.amazonaws.com", "ap-northeast-2": "config.ap-northeast-2.amazonaws.com",
                           "us-west-1": "config.us-west-1.amazonaws.com", "us-gov-east-1": "config.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "config.eu-west-3.amazonaws.com",
                           "cn-north-1": "config.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "config.sa-east-1.amazonaws.com",
                           "eu-west-1": "config.eu-west-1.amazonaws.com", "us-gov-west-1": "config.us-gov-west-1.amazonaws.com", "ap-southeast-2": "config.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "config.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "config.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "config.ap-southeast-1.amazonaws.com",
      "us-west-2": "config.us-west-2.amazonaws.com",
      "eu-west-2": "config.eu-west-2.amazonaws.com",
      "ap-northeast-3": "config.ap-northeast-3.amazonaws.com",
      "eu-central-1": "config.eu-central-1.amazonaws.com",
      "us-east-2": "config.us-east-2.amazonaws.com",
      "us-east-1": "config.us-east-1.amazonaws.com",
      "cn-northwest-1": "config.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "config.ap-south-1.amazonaws.com",
      "eu-north-1": "config.eu-north-1.amazonaws.com",
      "ap-northeast-2": "config.ap-northeast-2.amazonaws.com",
      "us-west-1": "config.us-west-1.amazonaws.com",
      "us-gov-east-1": "config.us-gov-east-1.amazonaws.com",
      "eu-west-3": "config.eu-west-3.amazonaws.com",
      "cn-north-1": "config.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "config.sa-east-1.amazonaws.com",
      "eu-west-1": "config.eu-west-1.amazonaws.com",
      "us-gov-west-1": "config.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "config.ap-southeast-2.amazonaws.com",
      "ca-central-1": "config.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "config"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_BatchGetAggregateResourceConfig_21625779 = ref object of OpenApiRestCall_21625435
proc url_BatchGetAggregateResourceConfig_21625781(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetAggregateResourceConfig_21625780(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns the current configuration items for resources that are present in your AWS Config aggregator. The operation also returns a list of resources that are not processed in the current request. If there are no unprocessed resources, the operation returns an empty <code>unprocessedResourceIdentifiers</code> list. </p> <note> <ul> <li> <p>The API does not return results for deleted resources.</p> </li> <li> <p> The API does not return tags and relationships.</p> </li> </ul> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625882 = header.getOrDefault("X-Amz-Date")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Date", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Security-Token", valid_21625883
  var valid_21625898 = header.getOrDefault("X-Amz-Target")
  valid_21625898 = validateParameter(valid_21625898, JString, required = true, default = newJString(
      "StarlingDoveService.BatchGetAggregateResourceConfig"))
  if valid_21625898 != nil:
    section.add "X-Amz-Target", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Algorithm", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Signature")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Signature", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Credential")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Credential", valid_21625903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21625929: Call_BatchGetAggregateResourceConfig_21625779;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the current configuration items for resources that are present in your AWS Config aggregator. The operation also returns a list of resources that are not processed in the current request. If there are no unprocessed resources, the operation returns an empty <code>unprocessedResourceIdentifiers</code> list. </p> <note> <ul> <li> <p>The API does not return results for deleted resources.</p> </li> <li> <p> The API does not return tags and relationships.</p> </li> </ul> </note>
  ## 
  let valid = call_21625929.validator(path, query, header, formData, body, _)
  let scheme = call_21625929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625929.makeUrl(scheme.get, call_21625929.host, call_21625929.base,
                               call_21625929.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625929, uri, valid, _)

proc call*(call_21625992: Call_BatchGetAggregateResourceConfig_21625779;
          body: JsonNode): Recallable =
  ## batchGetAggregateResourceConfig
  ## <p>Returns the current configuration items for resources that are present in your AWS Config aggregator. The operation also returns a list of resources that are not processed in the current request. If there are no unprocessed resources, the operation returns an empty <code>unprocessedResourceIdentifiers</code> list. </p> <note> <ul> <li> <p>The API does not return results for deleted resources.</p> </li> <li> <p> The API does not return tags and relationships.</p> </li> </ul> </note>
  ##   body: JObject (required)
  var body_21625993 = newJObject()
  if body != nil:
    body_21625993 = body
  result = call_21625992.call(nil, nil, nil, nil, body_21625993)

var batchGetAggregateResourceConfig* = Call_BatchGetAggregateResourceConfig_21625779(
    name: "batchGetAggregateResourceConfig", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.BatchGetAggregateResourceConfig",
    validator: validate_BatchGetAggregateResourceConfig_21625780, base: "/",
    makeUrl: url_BatchGetAggregateResourceConfig_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetResourceConfig_21626029 = ref object of OpenApiRestCall_21625435
proc url_BatchGetResourceConfig_21626031(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetResourceConfig_21626030(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns the current configuration for one or more requested resources. The operation also returns a list of resources that are not processed in the current request. If there are no unprocessed resources, the operation returns an empty unprocessedResourceKeys list. </p> <note> <ul> <li> <p>The API does not return results for deleted resources.</p> </li> <li> <p> The API does not return any tags for the requested resources. This information is filtered out of the supplementaryConfiguration section of the API response.</p> </li> </ul> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626032 = header.getOrDefault("X-Amz-Date")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Date", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Security-Token", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Target")
  valid_21626034 = validateParameter(valid_21626034, JString, required = true, default = newJString(
      "StarlingDoveService.BatchGetResourceConfig"))
  if valid_21626034 != nil:
    section.add "X-Amz-Target", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Algorithm", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Signature")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Signature", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Credential")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Credential", valid_21626039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626041: Call_BatchGetResourceConfig_21626029;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the current configuration for one or more requested resources. The operation also returns a list of resources that are not processed in the current request. If there are no unprocessed resources, the operation returns an empty unprocessedResourceKeys list. </p> <note> <ul> <li> <p>The API does not return results for deleted resources.</p> </li> <li> <p> The API does not return any tags for the requested resources. This information is filtered out of the supplementaryConfiguration section of the API response.</p> </li> </ul> </note>
  ## 
  let valid = call_21626041.validator(path, query, header, formData, body, _)
  let scheme = call_21626041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626041.makeUrl(scheme.get, call_21626041.host, call_21626041.base,
                               call_21626041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626041, uri, valid, _)

proc call*(call_21626042: Call_BatchGetResourceConfig_21626029; body: JsonNode): Recallable =
  ## batchGetResourceConfig
  ## <p>Returns the current configuration for one or more requested resources. The operation also returns a list of resources that are not processed in the current request. If there are no unprocessed resources, the operation returns an empty unprocessedResourceKeys list. </p> <note> <ul> <li> <p>The API does not return results for deleted resources.</p> </li> <li> <p> The API does not return any tags for the requested resources. This information is filtered out of the supplementaryConfiguration section of the API response.</p> </li> </ul> </note>
  ##   body: JObject (required)
  var body_21626043 = newJObject()
  if body != nil:
    body_21626043 = body
  result = call_21626042.call(nil, nil, nil, nil, body_21626043)

var batchGetResourceConfig* = Call_BatchGetResourceConfig_21626029(
    name: "batchGetResourceConfig", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.BatchGetResourceConfig",
    validator: validate_BatchGetResourceConfig_21626030, base: "/",
    makeUrl: url_BatchGetResourceConfig_21626031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAggregationAuthorization_21626044 = ref object of OpenApiRestCall_21625435
proc url_DeleteAggregationAuthorization_21626046(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAggregationAuthorization_21626045(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes the authorization granted to the specified configuration aggregator account in a specified region.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626047 = header.getOrDefault("X-Amz-Date")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Date", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Security-Token", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Target")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteAggregationAuthorization"))
  if valid_21626049 != nil:
    section.add "X-Amz-Target", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Algorithm", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Signature")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Signature", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Credential")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Credential", valid_21626054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626056: Call_DeleteAggregationAuthorization_21626044;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the authorization granted to the specified configuration aggregator account in a specified region.
  ## 
  let valid = call_21626056.validator(path, query, header, formData, body, _)
  let scheme = call_21626056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626056.makeUrl(scheme.get, call_21626056.host, call_21626056.base,
                               call_21626056.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626056, uri, valid, _)

proc call*(call_21626057: Call_DeleteAggregationAuthorization_21626044;
          body: JsonNode): Recallable =
  ## deleteAggregationAuthorization
  ## Deletes the authorization granted to the specified configuration aggregator account in a specified region.
  ##   body: JObject (required)
  var body_21626058 = newJObject()
  if body != nil:
    body_21626058 = body
  result = call_21626057.call(nil, nil, nil, nil, body_21626058)

var deleteAggregationAuthorization* = Call_DeleteAggregationAuthorization_21626044(
    name: "deleteAggregationAuthorization", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteAggregationAuthorization",
    validator: validate_DeleteAggregationAuthorization_21626045, base: "/",
    makeUrl: url_DeleteAggregationAuthorization_21626046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigRule_21626059 = ref object of OpenApiRestCall_21625435
proc url_DeleteConfigRule_21626061(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConfigRule_21626060(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes the specified AWS Config rule and all of its evaluation results.</p> <p>AWS Config sets the state of a rule to <code>DELETING</code> until the deletion is complete. You cannot update a rule while it is in this state. If you make a <code>PutConfigRule</code> or <code>DeleteConfigRule</code> request for the rule, you will receive a <code>ResourceInUseException</code>.</p> <p>You can check the state of a rule by using the <code>DescribeConfigRules</code> request.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626062 = header.getOrDefault("X-Amz-Date")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Date", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Security-Token", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Target")
  valid_21626064 = validateParameter(valid_21626064, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteConfigRule"))
  if valid_21626064 != nil:
    section.add "X-Amz-Target", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Algorithm", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Signature")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Signature", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Credential")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Credential", valid_21626069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626071: Call_DeleteConfigRule_21626059; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified AWS Config rule and all of its evaluation results.</p> <p>AWS Config sets the state of a rule to <code>DELETING</code> until the deletion is complete. You cannot update a rule while it is in this state. If you make a <code>PutConfigRule</code> or <code>DeleteConfigRule</code> request for the rule, you will receive a <code>ResourceInUseException</code>.</p> <p>You can check the state of a rule by using the <code>DescribeConfigRules</code> request.</p>
  ## 
  let valid = call_21626071.validator(path, query, header, formData, body, _)
  let scheme = call_21626071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626071.makeUrl(scheme.get, call_21626071.host, call_21626071.base,
                               call_21626071.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626071, uri, valid, _)

proc call*(call_21626072: Call_DeleteConfigRule_21626059; body: JsonNode): Recallable =
  ## deleteConfigRule
  ## <p>Deletes the specified AWS Config rule and all of its evaluation results.</p> <p>AWS Config sets the state of a rule to <code>DELETING</code> until the deletion is complete. You cannot update a rule while it is in this state. If you make a <code>PutConfigRule</code> or <code>DeleteConfigRule</code> request for the rule, you will receive a <code>ResourceInUseException</code>.</p> <p>You can check the state of a rule by using the <code>DescribeConfigRules</code> request.</p>
  ##   body: JObject (required)
  var body_21626073 = newJObject()
  if body != nil:
    body_21626073 = body
  result = call_21626072.call(nil, nil, nil, nil, body_21626073)

var deleteConfigRule* = Call_DeleteConfigRule_21626059(name: "deleteConfigRule",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteConfigRule",
    validator: validate_DeleteConfigRule_21626060, base: "/",
    makeUrl: url_DeleteConfigRule_21626061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationAggregator_21626074 = ref object of OpenApiRestCall_21625435
proc url_DeleteConfigurationAggregator_21626076(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConfigurationAggregator_21626075(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes the specified configuration aggregator and the aggregated data associated with the aggregator.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626077 = header.getOrDefault("X-Amz-Date")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Date", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Security-Token", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Target")
  valid_21626079 = validateParameter(valid_21626079, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteConfigurationAggregator"))
  if valid_21626079 != nil:
    section.add "X-Amz-Target", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Algorithm", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Signature")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Signature", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Credential")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Credential", valid_21626084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626086: Call_DeleteConfigurationAggregator_21626074;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified configuration aggregator and the aggregated data associated with the aggregator.
  ## 
  let valid = call_21626086.validator(path, query, header, formData, body, _)
  let scheme = call_21626086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626086.makeUrl(scheme.get, call_21626086.host, call_21626086.base,
                               call_21626086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626086, uri, valid, _)

proc call*(call_21626087: Call_DeleteConfigurationAggregator_21626074;
          body: JsonNode): Recallable =
  ## deleteConfigurationAggregator
  ## Deletes the specified configuration aggregator and the aggregated data associated with the aggregator.
  ##   body: JObject (required)
  var body_21626088 = newJObject()
  if body != nil:
    body_21626088 = body
  result = call_21626087.call(nil, nil, nil, nil, body_21626088)

var deleteConfigurationAggregator* = Call_DeleteConfigurationAggregator_21626074(
    name: "deleteConfigurationAggregator", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteConfigurationAggregator",
    validator: validate_DeleteConfigurationAggregator_21626075, base: "/",
    makeUrl: url_DeleteConfigurationAggregator_21626076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationRecorder_21626089 = ref object of OpenApiRestCall_21625435
proc url_DeleteConfigurationRecorder_21626091(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConfigurationRecorder_21626090(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes the configuration recorder.</p> <p>After the configuration recorder is deleted, AWS Config will not record resource configuration changes until you create a new configuration recorder.</p> <p>This action does not delete the configuration information that was previously recorded. You will be able to access the previously recorded information by using the <code>GetResourceConfigHistory</code> action, but you will not be able to access this information in the AWS Config console until you create a new configuration recorder.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626092 = header.getOrDefault("X-Amz-Date")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Date", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Security-Token", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Target")
  valid_21626094 = validateParameter(valid_21626094, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteConfigurationRecorder"))
  if valid_21626094 != nil:
    section.add "X-Amz-Target", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Algorithm", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Signature")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Signature", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Credential")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Credential", valid_21626099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626101: Call_DeleteConfigurationRecorder_21626089;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the configuration recorder.</p> <p>After the configuration recorder is deleted, AWS Config will not record resource configuration changes until you create a new configuration recorder.</p> <p>This action does not delete the configuration information that was previously recorded. You will be able to access the previously recorded information by using the <code>GetResourceConfigHistory</code> action, but you will not be able to access this information in the AWS Config console until you create a new configuration recorder.</p>
  ## 
  let valid = call_21626101.validator(path, query, header, formData, body, _)
  let scheme = call_21626101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626101.makeUrl(scheme.get, call_21626101.host, call_21626101.base,
                               call_21626101.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626101, uri, valid, _)

proc call*(call_21626102: Call_DeleteConfigurationRecorder_21626089; body: JsonNode): Recallable =
  ## deleteConfigurationRecorder
  ## <p>Deletes the configuration recorder.</p> <p>After the configuration recorder is deleted, AWS Config will not record resource configuration changes until you create a new configuration recorder.</p> <p>This action does not delete the configuration information that was previously recorded. You will be able to access the previously recorded information by using the <code>GetResourceConfigHistory</code> action, but you will not be able to access this information in the AWS Config console until you create a new configuration recorder.</p>
  ##   body: JObject (required)
  var body_21626103 = newJObject()
  if body != nil:
    body_21626103 = body
  result = call_21626102.call(nil, nil, nil, nil, body_21626103)

var deleteConfigurationRecorder* = Call_DeleteConfigurationRecorder_21626089(
    name: "deleteConfigurationRecorder", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteConfigurationRecorder",
    validator: validate_DeleteConfigurationRecorder_21626090, base: "/",
    makeUrl: url_DeleteConfigurationRecorder_21626091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConformancePack_21626104 = ref object of OpenApiRestCall_21625435
proc url_DeleteConformancePack_21626106(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConformancePack_21626105(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes the specified conformance pack and all the AWS Config rules, remediation actions, and all evaluation results within that conformance pack.</p> <p>AWS Config sets the conformance pack to <code>DELETE_IN_PROGRESS</code> until the deletion is complete. You cannot update a conformance pack while it is in this state.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626107 = header.getOrDefault("X-Amz-Date")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Date", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Security-Token", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Target")
  valid_21626109 = validateParameter(valid_21626109, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteConformancePack"))
  if valid_21626109 != nil:
    section.add "X-Amz-Target", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Algorithm", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Signature")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Signature", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Credential")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Credential", valid_21626114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626116: Call_DeleteConformancePack_21626104;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified conformance pack and all the AWS Config rules, remediation actions, and all evaluation results within that conformance pack.</p> <p>AWS Config sets the conformance pack to <code>DELETE_IN_PROGRESS</code> until the deletion is complete. You cannot update a conformance pack while it is in this state.</p>
  ## 
  let valid = call_21626116.validator(path, query, header, formData, body, _)
  let scheme = call_21626116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626116.makeUrl(scheme.get, call_21626116.host, call_21626116.base,
                               call_21626116.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626116, uri, valid, _)

proc call*(call_21626117: Call_DeleteConformancePack_21626104; body: JsonNode): Recallable =
  ## deleteConformancePack
  ## <p>Deletes the specified conformance pack and all the AWS Config rules, remediation actions, and all evaluation results within that conformance pack.</p> <p>AWS Config sets the conformance pack to <code>DELETE_IN_PROGRESS</code> until the deletion is complete. You cannot update a conformance pack while it is in this state.</p>
  ##   body: JObject (required)
  var body_21626118 = newJObject()
  if body != nil:
    body_21626118 = body
  result = call_21626117.call(nil, nil, nil, nil, body_21626118)

var deleteConformancePack* = Call_DeleteConformancePack_21626104(
    name: "deleteConformancePack", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteConformancePack",
    validator: validate_DeleteConformancePack_21626105, base: "/",
    makeUrl: url_DeleteConformancePack_21626106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeliveryChannel_21626119 = ref object of OpenApiRestCall_21625435
proc url_DeleteDeliveryChannel_21626121(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDeliveryChannel_21626120(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes the delivery channel.</p> <p>Before you can delete the delivery channel, you must stop the configuration recorder by using the <a>StopConfigurationRecorder</a> action.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626122 = header.getOrDefault("X-Amz-Date")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Date", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Security-Token", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Target")
  valid_21626124 = validateParameter(valid_21626124, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteDeliveryChannel"))
  if valid_21626124 != nil:
    section.add "X-Amz-Target", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Algorithm", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Signature")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Signature", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Credential")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Credential", valid_21626129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626131: Call_DeleteDeliveryChannel_21626119;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the delivery channel.</p> <p>Before you can delete the delivery channel, you must stop the configuration recorder by using the <a>StopConfigurationRecorder</a> action.</p>
  ## 
  let valid = call_21626131.validator(path, query, header, formData, body, _)
  let scheme = call_21626131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626131.makeUrl(scheme.get, call_21626131.host, call_21626131.base,
                               call_21626131.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626131, uri, valid, _)

proc call*(call_21626132: Call_DeleteDeliveryChannel_21626119; body: JsonNode): Recallable =
  ## deleteDeliveryChannel
  ## <p>Deletes the delivery channel.</p> <p>Before you can delete the delivery channel, you must stop the configuration recorder by using the <a>StopConfigurationRecorder</a> action.</p>
  ##   body: JObject (required)
  var body_21626133 = newJObject()
  if body != nil:
    body_21626133 = body
  result = call_21626132.call(nil, nil, nil, nil, body_21626133)

var deleteDeliveryChannel* = Call_DeleteDeliveryChannel_21626119(
    name: "deleteDeliveryChannel", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteDeliveryChannel",
    validator: validate_DeleteDeliveryChannel_21626120, base: "/",
    makeUrl: url_DeleteDeliveryChannel_21626121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEvaluationResults_21626134 = ref object of OpenApiRestCall_21625435
proc url_DeleteEvaluationResults_21626136(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEvaluationResults_21626135(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the evaluation results for the specified AWS Config rule. You can specify one AWS Config rule per request. After you delete the evaluation results, you can call the <a>StartConfigRulesEvaluation</a> API to start evaluating your AWS resources against the rule.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626137 = header.getOrDefault("X-Amz-Date")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Date", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Security-Token", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Target")
  valid_21626139 = validateParameter(valid_21626139, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteEvaluationResults"))
  if valid_21626139 != nil:
    section.add "X-Amz-Target", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Algorithm", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Signature")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Signature", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Credential")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Credential", valid_21626144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626146: Call_DeleteEvaluationResults_21626134;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the evaluation results for the specified AWS Config rule. You can specify one AWS Config rule per request. After you delete the evaluation results, you can call the <a>StartConfigRulesEvaluation</a> API to start evaluating your AWS resources against the rule.
  ## 
  let valid = call_21626146.validator(path, query, header, formData, body, _)
  let scheme = call_21626146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626146.makeUrl(scheme.get, call_21626146.host, call_21626146.base,
                               call_21626146.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626146, uri, valid, _)

proc call*(call_21626147: Call_DeleteEvaluationResults_21626134; body: JsonNode): Recallable =
  ## deleteEvaluationResults
  ## Deletes the evaluation results for the specified AWS Config rule. You can specify one AWS Config rule per request. After you delete the evaluation results, you can call the <a>StartConfigRulesEvaluation</a> API to start evaluating your AWS resources against the rule.
  ##   body: JObject (required)
  var body_21626148 = newJObject()
  if body != nil:
    body_21626148 = body
  result = call_21626147.call(nil, nil, nil, nil, body_21626148)

var deleteEvaluationResults* = Call_DeleteEvaluationResults_21626134(
    name: "deleteEvaluationResults", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteEvaluationResults",
    validator: validate_DeleteEvaluationResults_21626135, base: "/",
    makeUrl: url_DeleteEvaluationResults_21626136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOrganizationConfigRule_21626149 = ref object of OpenApiRestCall_21625435
proc url_DeleteOrganizationConfigRule_21626151(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteOrganizationConfigRule_21626150(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Deletes the specified organization config rule and all of its evaluation results from all member accounts in that organization. Only a master account can delete an organization config rule.</p> <p>AWS Config sets the state of a rule to DELETE_IN_PROGRESS until the deletion is complete. You cannot update a rule while it is in this state.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626152 = header.getOrDefault("X-Amz-Date")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Date", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Security-Token", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Target")
  valid_21626154 = validateParameter(valid_21626154, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteOrganizationConfigRule"))
  if valid_21626154 != nil:
    section.add "X-Amz-Target", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Algorithm", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Signature")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Signature", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Credential")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Credential", valid_21626159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626161: Call_DeleteOrganizationConfigRule_21626149;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified organization config rule and all of its evaluation results from all member accounts in that organization. Only a master account can delete an organization config rule.</p> <p>AWS Config sets the state of a rule to DELETE_IN_PROGRESS until the deletion is complete. You cannot update a rule while it is in this state.</p>
  ## 
  let valid = call_21626161.validator(path, query, header, formData, body, _)
  let scheme = call_21626161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626161.makeUrl(scheme.get, call_21626161.host, call_21626161.base,
                               call_21626161.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626161, uri, valid, _)

proc call*(call_21626162: Call_DeleteOrganizationConfigRule_21626149;
          body: JsonNode): Recallable =
  ## deleteOrganizationConfigRule
  ## <p>Deletes the specified organization config rule and all of its evaluation results from all member accounts in that organization. Only a master account can delete an organization config rule.</p> <p>AWS Config sets the state of a rule to DELETE_IN_PROGRESS until the deletion is complete. You cannot update a rule while it is in this state.</p>
  ##   body: JObject (required)
  var body_21626163 = newJObject()
  if body != nil:
    body_21626163 = body
  result = call_21626162.call(nil, nil, nil, nil, body_21626163)

var deleteOrganizationConfigRule* = Call_DeleteOrganizationConfigRule_21626149(
    name: "deleteOrganizationConfigRule", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteOrganizationConfigRule",
    validator: validate_DeleteOrganizationConfigRule_21626150, base: "/",
    makeUrl: url_DeleteOrganizationConfigRule_21626151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOrganizationConformancePack_21626164 = ref object of OpenApiRestCall_21625435
proc url_DeleteOrganizationConformancePack_21626166(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteOrganizationConformancePack_21626165(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Deletes the specified organization conformance pack and all of the config rules and remediation actions from all member accounts in that organization. Only a master account can delete an organization conformance pack.</p> <p>AWS Config sets the state of a conformance pack to DELETE_IN_PROGRESS until the deletion is complete. You cannot update a conformance pack while it is in this state. </p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626167 = header.getOrDefault("X-Amz-Date")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Date", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Security-Token", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Target")
  valid_21626169 = validateParameter(valid_21626169, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteOrganizationConformancePack"))
  if valid_21626169 != nil:
    section.add "X-Amz-Target", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Algorithm", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Signature")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Signature", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Credential")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Credential", valid_21626174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626176: Call_DeleteOrganizationConformancePack_21626164;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified organization conformance pack and all of the config rules and remediation actions from all member accounts in that organization. Only a master account can delete an organization conformance pack.</p> <p>AWS Config sets the state of a conformance pack to DELETE_IN_PROGRESS until the deletion is complete. You cannot update a conformance pack while it is in this state. </p>
  ## 
  let valid = call_21626176.validator(path, query, header, formData, body, _)
  let scheme = call_21626176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626176.makeUrl(scheme.get, call_21626176.host, call_21626176.base,
                               call_21626176.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626176, uri, valid, _)

proc call*(call_21626177: Call_DeleteOrganizationConformancePack_21626164;
          body: JsonNode): Recallable =
  ## deleteOrganizationConformancePack
  ## <p>Deletes the specified organization conformance pack and all of the config rules and remediation actions from all member accounts in that organization. Only a master account can delete an organization conformance pack.</p> <p>AWS Config sets the state of a conformance pack to DELETE_IN_PROGRESS until the deletion is complete. You cannot update a conformance pack while it is in this state. </p>
  ##   body: JObject (required)
  var body_21626178 = newJObject()
  if body != nil:
    body_21626178 = body
  result = call_21626177.call(nil, nil, nil, nil, body_21626178)

var deleteOrganizationConformancePack* = Call_DeleteOrganizationConformancePack_21626164(
    name: "deleteOrganizationConformancePack", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DeleteOrganizationConformancePack",
    validator: validate_DeleteOrganizationConformancePack_21626165, base: "/",
    makeUrl: url_DeleteOrganizationConformancePack_21626166,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePendingAggregationRequest_21626179 = ref object of OpenApiRestCall_21625435
proc url_DeletePendingAggregationRequest_21626181(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePendingAggregationRequest_21626180(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes pending authorization requests for a specified aggregator account in a specified region.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626182 = header.getOrDefault("X-Amz-Date")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Date", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Security-Token", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Target")
  valid_21626184 = validateParameter(valid_21626184, JString, required = true, default = newJString(
      "StarlingDoveService.DeletePendingAggregationRequest"))
  if valid_21626184 != nil:
    section.add "X-Amz-Target", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Algorithm", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Signature")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Signature", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Credential")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Credential", valid_21626189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626191: Call_DeletePendingAggregationRequest_21626179;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes pending authorization requests for a specified aggregator account in a specified region.
  ## 
  let valid = call_21626191.validator(path, query, header, formData, body, _)
  let scheme = call_21626191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626191.makeUrl(scheme.get, call_21626191.host, call_21626191.base,
                               call_21626191.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626191, uri, valid, _)

proc call*(call_21626192: Call_DeletePendingAggregationRequest_21626179;
          body: JsonNode): Recallable =
  ## deletePendingAggregationRequest
  ## Deletes pending authorization requests for a specified aggregator account in a specified region.
  ##   body: JObject (required)
  var body_21626193 = newJObject()
  if body != nil:
    body_21626193 = body
  result = call_21626192.call(nil, nil, nil, nil, body_21626193)

var deletePendingAggregationRequest* = Call_DeletePendingAggregationRequest_21626179(
    name: "deletePendingAggregationRequest", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DeletePendingAggregationRequest",
    validator: validate_DeletePendingAggregationRequest_21626180, base: "/",
    makeUrl: url_DeletePendingAggregationRequest_21626181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRemediationConfiguration_21626194 = ref object of OpenApiRestCall_21625435
proc url_DeleteRemediationConfiguration_21626196(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRemediationConfiguration_21626195(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes the remediation configuration.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626197 = header.getOrDefault("X-Amz-Date")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Date", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Security-Token", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Target")
  valid_21626199 = validateParameter(valid_21626199, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteRemediationConfiguration"))
  if valid_21626199 != nil:
    section.add "X-Amz-Target", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Algorithm", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Signature")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Signature", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Credential")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Credential", valid_21626204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626206: Call_DeleteRemediationConfiguration_21626194;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the remediation configuration.
  ## 
  let valid = call_21626206.validator(path, query, header, formData, body, _)
  let scheme = call_21626206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626206.makeUrl(scheme.get, call_21626206.host, call_21626206.base,
                               call_21626206.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626206, uri, valid, _)

proc call*(call_21626207: Call_DeleteRemediationConfiguration_21626194;
          body: JsonNode): Recallable =
  ## deleteRemediationConfiguration
  ## Deletes the remediation configuration.
  ##   body: JObject (required)
  var body_21626208 = newJObject()
  if body != nil:
    body_21626208 = body
  result = call_21626207.call(nil, nil, nil, nil, body_21626208)

var deleteRemediationConfiguration* = Call_DeleteRemediationConfiguration_21626194(
    name: "deleteRemediationConfiguration", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteRemediationConfiguration",
    validator: validate_DeleteRemediationConfiguration_21626195, base: "/",
    makeUrl: url_DeleteRemediationConfiguration_21626196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRemediationExceptions_21626209 = ref object of OpenApiRestCall_21625435
proc url_DeleteRemediationExceptions_21626211(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRemediationExceptions_21626210(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes one or more remediation exceptions mentioned in the resource keys.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626212 = header.getOrDefault("X-Amz-Date")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Date", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Security-Token", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Target")
  valid_21626214 = validateParameter(valid_21626214, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteRemediationExceptions"))
  if valid_21626214 != nil:
    section.add "X-Amz-Target", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Algorithm", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Signature")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Signature", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Credential")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Credential", valid_21626219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626221: Call_DeleteRemediationExceptions_21626209;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes one or more remediation exceptions mentioned in the resource keys.
  ## 
  let valid = call_21626221.validator(path, query, header, formData, body, _)
  let scheme = call_21626221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626221.makeUrl(scheme.get, call_21626221.host, call_21626221.base,
                               call_21626221.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626221, uri, valid, _)

proc call*(call_21626222: Call_DeleteRemediationExceptions_21626209; body: JsonNode): Recallable =
  ## deleteRemediationExceptions
  ## Deletes one or more remediation exceptions mentioned in the resource keys.
  ##   body: JObject (required)
  var body_21626223 = newJObject()
  if body != nil:
    body_21626223 = body
  result = call_21626222.call(nil, nil, nil, nil, body_21626223)

var deleteRemediationExceptions* = Call_DeleteRemediationExceptions_21626209(
    name: "deleteRemediationExceptions", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteRemediationExceptions",
    validator: validate_DeleteRemediationExceptions_21626210, base: "/",
    makeUrl: url_DeleteRemediationExceptions_21626211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceConfig_21626224 = ref object of OpenApiRestCall_21625435
proc url_DeleteResourceConfig_21626226(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteResourceConfig_21626225(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Records the configuration state for a custom resource that has been deleted. This API records a new ConfigurationItem with a ResourceDeleted status. You can retrieve the ConfigurationItems recorded for this resource in your AWS Config History. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626227 = header.getOrDefault("X-Amz-Date")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Date", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Security-Token", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Target")
  valid_21626229 = validateParameter(valid_21626229, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteResourceConfig"))
  if valid_21626229 != nil:
    section.add "X-Amz-Target", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Algorithm", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Signature")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Signature", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Credential")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Credential", valid_21626234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626236: Call_DeleteResourceConfig_21626224; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Records the configuration state for a custom resource that has been deleted. This API records a new ConfigurationItem with a ResourceDeleted status. You can retrieve the ConfigurationItems recorded for this resource in your AWS Config History. 
  ## 
  let valid = call_21626236.validator(path, query, header, formData, body, _)
  let scheme = call_21626236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626236.makeUrl(scheme.get, call_21626236.host, call_21626236.base,
                               call_21626236.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626236, uri, valid, _)

proc call*(call_21626237: Call_DeleteResourceConfig_21626224; body: JsonNode): Recallable =
  ## deleteResourceConfig
  ## Records the configuration state for a custom resource that has been deleted. This API records a new ConfigurationItem with a ResourceDeleted status. You can retrieve the ConfigurationItems recorded for this resource in your AWS Config History. 
  ##   body: JObject (required)
  var body_21626238 = newJObject()
  if body != nil:
    body_21626238 = body
  result = call_21626237.call(nil, nil, nil, nil, body_21626238)

var deleteResourceConfig* = Call_DeleteResourceConfig_21626224(
    name: "deleteResourceConfig", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteResourceConfig",
    validator: validate_DeleteResourceConfig_21626225, base: "/",
    makeUrl: url_DeleteResourceConfig_21626226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRetentionConfiguration_21626239 = ref object of OpenApiRestCall_21625435
proc url_DeleteRetentionConfiguration_21626241(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRetentionConfiguration_21626240(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes the retention configuration.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626242 = header.getOrDefault("X-Amz-Date")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-Date", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Security-Token", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-Target")
  valid_21626244 = validateParameter(valid_21626244, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteRetentionConfiguration"))
  if valid_21626244 != nil:
    section.add "X-Amz-Target", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Algorithm", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Signature")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Signature", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Credential")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Credential", valid_21626249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626251: Call_DeleteRetentionConfiguration_21626239;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the retention configuration.
  ## 
  let valid = call_21626251.validator(path, query, header, formData, body, _)
  let scheme = call_21626251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626251.makeUrl(scheme.get, call_21626251.host, call_21626251.base,
                               call_21626251.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626251, uri, valid, _)

proc call*(call_21626252: Call_DeleteRetentionConfiguration_21626239;
          body: JsonNode): Recallable =
  ## deleteRetentionConfiguration
  ## Deletes the retention configuration.
  ##   body: JObject (required)
  var body_21626253 = newJObject()
  if body != nil:
    body_21626253 = body
  result = call_21626252.call(nil, nil, nil, nil, body_21626253)

var deleteRetentionConfiguration* = Call_DeleteRetentionConfiguration_21626239(
    name: "deleteRetentionConfiguration", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteRetentionConfiguration",
    validator: validate_DeleteRetentionConfiguration_21626240, base: "/",
    makeUrl: url_DeleteRetentionConfiguration_21626241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeliverConfigSnapshot_21626254 = ref object of OpenApiRestCall_21625435
proc url_DeliverConfigSnapshot_21626256(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeliverConfigSnapshot_21626255(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Schedules delivery of a configuration snapshot to the Amazon S3 bucket in the specified delivery channel. After the delivery has started, AWS Config sends the following notifications using an Amazon SNS topic that you have specified.</p> <ul> <li> <p>Notification of the start of the delivery.</p> </li> <li> <p>Notification of the completion of the delivery, if the delivery was successfully completed.</p> </li> <li> <p>Notification of delivery failure, if the delivery failed.</p> </li> </ul>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626257 = header.getOrDefault("X-Amz-Date")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-Date", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Security-Token", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Target")
  valid_21626259 = validateParameter(valid_21626259, JString, required = true, default = newJString(
      "StarlingDoveService.DeliverConfigSnapshot"))
  if valid_21626259 != nil:
    section.add "X-Amz-Target", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Algorithm", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Signature")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Signature", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Credential")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Credential", valid_21626264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626266: Call_DeliverConfigSnapshot_21626254;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Schedules delivery of a configuration snapshot to the Amazon S3 bucket in the specified delivery channel. After the delivery has started, AWS Config sends the following notifications using an Amazon SNS topic that you have specified.</p> <ul> <li> <p>Notification of the start of the delivery.</p> </li> <li> <p>Notification of the completion of the delivery, if the delivery was successfully completed.</p> </li> <li> <p>Notification of delivery failure, if the delivery failed.</p> </li> </ul>
  ## 
  let valid = call_21626266.validator(path, query, header, formData, body, _)
  let scheme = call_21626266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626266.makeUrl(scheme.get, call_21626266.host, call_21626266.base,
                               call_21626266.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626266, uri, valid, _)

proc call*(call_21626267: Call_DeliverConfigSnapshot_21626254; body: JsonNode): Recallable =
  ## deliverConfigSnapshot
  ## <p>Schedules delivery of a configuration snapshot to the Amazon S3 bucket in the specified delivery channel. After the delivery has started, AWS Config sends the following notifications using an Amazon SNS topic that you have specified.</p> <ul> <li> <p>Notification of the start of the delivery.</p> </li> <li> <p>Notification of the completion of the delivery, if the delivery was successfully completed.</p> </li> <li> <p>Notification of delivery failure, if the delivery failed.</p> </li> </ul>
  ##   body: JObject (required)
  var body_21626268 = newJObject()
  if body != nil:
    body_21626268 = body
  result = call_21626267.call(nil, nil, nil, nil, body_21626268)

var deliverConfigSnapshot* = Call_DeliverConfigSnapshot_21626254(
    name: "deliverConfigSnapshot", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeliverConfigSnapshot",
    validator: validate_DeliverConfigSnapshot_21626255, base: "/",
    makeUrl: url_DeliverConfigSnapshot_21626256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAggregateComplianceByConfigRules_21626269 = ref object of OpenApiRestCall_21625435
proc url_DescribeAggregateComplianceByConfigRules_21626271(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAggregateComplianceByConfigRules_21626270(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns a list of compliant and noncompliant rules with the number of resources for compliant and noncompliant rules. </p> <note> <p>The results can return an empty result page, but if you have a <code>nextToken</code>, the results are displayed on the next page.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626272 = header.getOrDefault("X-Amz-Date")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Date", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Security-Token", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Target")
  valid_21626274 = validateParameter(valid_21626274, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeAggregateComplianceByConfigRules"))
  if valid_21626274 != nil:
    section.add "X-Amz-Target", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Algorithm", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Signature")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Signature", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Credential")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Credential", valid_21626279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626281: Call_DescribeAggregateComplianceByConfigRules_21626269;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of compliant and noncompliant rules with the number of resources for compliant and noncompliant rules. </p> <note> <p>The results can return an empty result page, but if you have a <code>nextToken</code>, the results are displayed on the next page.</p> </note>
  ## 
  let valid = call_21626281.validator(path, query, header, formData, body, _)
  let scheme = call_21626281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626281.makeUrl(scheme.get, call_21626281.host, call_21626281.base,
                               call_21626281.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626281, uri, valid, _)

proc call*(call_21626282: Call_DescribeAggregateComplianceByConfigRules_21626269;
          body: JsonNode): Recallable =
  ## describeAggregateComplianceByConfigRules
  ## <p>Returns a list of compliant and noncompliant rules with the number of resources for compliant and noncompliant rules. </p> <note> <p>The results can return an empty result page, but if you have a <code>nextToken</code>, the results are displayed on the next page.</p> </note>
  ##   body: JObject (required)
  var body_21626283 = newJObject()
  if body != nil:
    body_21626283 = body
  result = call_21626282.call(nil, nil, nil, nil, body_21626283)

var describeAggregateComplianceByConfigRules* = Call_DescribeAggregateComplianceByConfigRules_21626269(
    name: "describeAggregateComplianceByConfigRules", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeAggregateComplianceByConfigRules",
    validator: validate_DescribeAggregateComplianceByConfigRules_21626270,
    base: "/", makeUrl: url_DescribeAggregateComplianceByConfigRules_21626271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAggregationAuthorizations_21626284 = ref object of OpenApiRestCall_21625435
proc url_DescribeAggregationAuthorizations_21626286(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAggregationAuthorizations_21626285(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns a list of authorizations granted to various aggregator accounts and regions.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626287 = header.getOrDefault("X-Amz-Date")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Date", valid_21626287
  var valid_21626288 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Security-Token", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-Target")
  valid_21626289 = validateParameter(valid_21626289, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeAggregationAuthorizations"))
  if valid_21626289 != nil:
    section.add "X-Amz-Target", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Algorithm", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Signature")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Signature", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Credential")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Credential", valid_21626294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626296: Call_DescribeAggregationAuthorizations_21626284;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of authorizations granted to various aggregator accounts and regions.
  ## 
  let valid = call_21626296.validator(path, query, header, formData, body, _)
  let scheme = call_21626296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626296.makeUrl(scheme.get, call_21626296.host, call_21626296.base,
                               call_21626296.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626296, uri, valid, _)

proc call*(call_21626297: Call_DescribeAggregationAuthorizations_21626284;
          body: JsonNode): Recallable =
  ## describeAggregationAuthorizations
  ## Returns a list of authorizations granted to various aggregator accounts and regions.
  ##   body: JObject (required)
  var body_21626298 = newJObject()
  if body != nil:
    body_21626298 = body
  result = call_21626297.call(nil, nil, nil, nil, body_21626298)

var describeAggregationAuthorizations* = Call_DescribeAggregationAuthorizations_21626284(
    name: "describeAggregationAuthorizations", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeAggregationAuthorizations",
    validator: validate_DescribeAggregationAuthorizations_21626285, base: "/",
    makeUrl: url_DescribeAggregationAuthorizations_21626286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComplianceByConfigRule_21626299 = ref object of OpenApiRestCall_21625435
proc url_DescribeComplianceByConfigRule_21626301(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeComplianceByConfigRule_21626300(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Indicates whether the specified AWS Config rules are compliant. If a rule is noncompliant, this action returns the number of AWS resources that do not comply with the rule.</p> <p>A rule is compliant if all of the evaluated resources comply with it. It is noncompliant if any of these resources do not comply.</p> <p>If AWS Config has no current evaluation results for the rule, it returns <code>INSUFFICIENT_DATA</code>. This result might indicate one of the following conditions:</p> <ul> <li> <p>AWS Config has never invoked an evaluation for the rule. To check whether it has, use the <code>DescribeConfigRuleEvaluationStatus</code> action to get the <code>LastSuccessfulInvocationTime</code> and <code>LastFailedInvocationTime</code>.</p> </li> <li> <p>The rule's AWS Lambda function is failing to send evaluation results to AWS Config. Verify that the role you assigned to your configuration recorder includes the <code>config:PutEvaluations</code> permission. If the rule is a custom rule, verify that the AWS Lambda execution role includes the <code>config:PutEvaluations</code> permission.</p> </li> <li> <p>The rule's AWS Lambda function has returned <code>NOT_APPLICABLE</code> for all evaluation results. This can occur if the resources were deleted or removed from the rule's scope.</p> </li> </ul>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626302 = header.getOrDefault("X-Amz-Date")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Date", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Security-Token", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Target")
  valid_21626304 = validateParameter(valid_21626304, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeComplianceByConfigRule"))
  if valid_21626304 != nil:
    section.add "X-Amz-Target", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "X-Amz-Algorithm", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Signature")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Signature", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Credential")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Credential", valid_21626309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626311: Call_DescribeComplianceByConfigRule_21626299;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Indicates whether the specified AWS Config rules are compliant. If a rule is noncompliant, this action returns the number of AWS resources that do not comply with the rule.</p> <p>A rule is compliant if all of the evaluated resources comply with it. It is noncompliant if any of these resources do not comply.</p> <p>If AWS Config has no current evaluation results for the rule, it returns <code>INSUFFICIENT_DATA</code>. This result might indicate one of the following conditions:</p> <ul> <li> <p>AWS Config has never invoked an evaluation for the rule. To check whether it has, use the <code>DescribeConfigRuleEvaluationStatus</code> action to get the <code>LastSuccessfulInvocationTime</code> and <code>LastFailedInvocationTime</code>.</p> </li> <li> <p>The rule's AWS Lambda function is failing to send evaluation results to AWS Config. Verify that the role you assigned to your configuration recorder includes the <code>config:PutEvaluations</code> permission. If the rule is a custom rule, verify that the AWS Lambda execution role includes the <code>config:PutEvaluations</code> permission.</p> </li> <li> <p>The rule's AWS Lambda function has returned <code>NOT_APPLICABLE</code> for all evaluation results. This can occur if the resources were deleted or removed from the rule's scope.</p> </li> </ul>
  ## 
  let valid = call_21626311.validator(path, query, header, formData, body, _)
  let scheme = call_21626311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626311.makeUrl(scheme.get, call_21626311.host, call_21626311.base,
                               call_21626311.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626311, uri, valid, _)

proc call*(call_21626312: Call_DescribeComplianceByConfigRule_21626299;
          body: JsonNode): Recallable =
  ## describeComplianceByConfigRule
  ## <p>Indicates whether the specified AWS Config rules are compliant. If a rule is noncompliant, this action returns the number of AWS resources that do not comply with the rule.</p> <p>A rule is compliant if all of the evaluated resources comply with it. It is noncompliant if any of these resources do not comply.</p> <p>If AWS Config has no current evaluation results for the rule, it returns <code>INSUFFICIENT_DATA</code>. This result might indicate one of the following conditions:</p> <ul> <li> <p>AWS Config has never invoked an evaluation for the rule. To check whether it has, use the <code>DescribeConfigRuleEvaluationStatus</code> action to get the <code>LastSuccessfulInvocationTime</code> and <code>LastFailedInvocationTime</code>.</p> </li> <li> <p>The rule's AWS Lambda function is failing to send evaluation results to AWS Config. Verify that the role you assigned to your configuration recorder includes the <code>config:PutEvaluations</code> permission. If the rule is a custom rule, verify that the AWS Lambda execution role includes the <code>config:PutEvaluations</code> permission.</p> </li> <li> <p>The rule's AWS Lambda function has returned <code>NOT_APPLICABLE</code> for all evaluation results. This can occur if the resources were deleted or removed from the rule's scope.</p> </li> </ul>
  ##   body: JObject (required)
  var body_21626313 = newJObject()
  if body != nil:
    body_21626313 = body
  result = call_21626312.call(nil, nil, nil, nil, body_21626313)

var describeComplianceByConfigRule* = Call_DescribeComplianceByConfigRule_21626299(
    name: "describeComplianceByConfigRule", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeComplianceByConfigRule",
    validator: validate_DescribeComplianceByConfigRule_21626300, base: "/",
    makeUrl: url_DescribeComplianceByConfigRule_21626301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComplianceByResource_21626314 = ref object of OpenApiRestCall_21625435
proc url_DescribeComplianceByResource_21626316(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeComplianceByResource_21626315(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Indicates whether the specified AWS resources are compliant. If a resource is noncompliant, this action returns the number of AWS Config rules that the resource does not comply with.</p> <p>A resource is compliant if it complies with all the AWS Config rules that evaluate it. It is noncompliant if it does not comply with one or more of these rules.</p> <p>If AWS Config has no current evaluation results for the resource, it returns <code>INSUFFICIENT_DATA</code>. This result might indicate one of the following conditions about the rules that evaluate the resource:</p> <ul> <li> <p>AWS Config has never invoked an evaluation for the rule. To check whether it has, use the <code>DescribeConfigRuleEvaluationStatus</code> action to get the <code>LastSuccessfulInvocationTime</code> and <code>LastFailedInvocationTime</code>.</p> </li> <li> <p>The rule's AWS Lambda function is failing to send evaluation results to AWS Config. Verify that the role that you assigned to your configuration recorder includes the <code>config:PutEvaluations</code> permission. If the rule is a custom rule, verify that the AWS Lambda execution role includes the <code>config:PutEvaluations</code> permission.</p> </li> <li> <p>The rule's AWS Lambda function has returned <code>NOT_APPLICABLE</code> for all evaluation results. This can occur if the resources were deleted or removed from the rule's scope.</p> </li> </ul>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626317 = header.getOrDefault("X-Amz-Date")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Date", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-Security-Token", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Target")
  valid_21626319 = validateParameter(valid_21626319, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeComplianceByResource"))
  if valid_21626319 != nil:
    section.add "X-Amz-Target", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-Algorithm", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Signature")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Signature", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Credential")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Credential", valid_21626324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626326: Call_DescribeComplianceByResource_21626314;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Indicates whether the specified AWS resources are compliant. If a resource is noncompliant, this action returns the number of AWS Config rules that the resource does not comply with.</p> <p>A resource is compliant if it complies with all the AWS Config rules that evaluate it. It is noncompliant if it does not comply with one or more of these rules.</p> <p>If AWS Config has no current evaluation results for the resource, it returns <code>INSUFFICIENT_DATA</code>. This result might indicate one of the following conditions about the rules that evaluate the resource:</p> <ul> <li> <p>AWS Config has never invoked an evaluation for the rule. To check whether it has, use the <code>DescribeConfigRuleEvaluationStatus</code> action to get the <code>LastSuccessfulInvocationTime</code> and <code>LastFailedInvocationTime</code>.</p> </li> <li> <p>The rule's AWS Lambda function is failing to send evaluation results to AWS Config. Verify that the role that you assigned to your configuration recorder includes the <code>config:PutEvaluations</code> permission. If the rule is a custom rule, verify that the AWS Lambda execution role includes the <code>config:PutEvaluations</code> permission.</p> </li> <li> <p>The rule's AWS Lambda function has returned <code>NOT_APPLICABLE</code> for all evaluation results. This can occur if the resources were deleted or removed from the rule's scope.</p> </li> </ul>
  ## 
  let valid = call_21626326.validator(path, query, header, formData, body, _)
  let scheme = call_21626326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626326.makeUrl(scheme.get, call_21626326.host, call_21626326.base,
                               call_21626326.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626326, uri, valid, _)

proc call*(call_21626327: Call_DescribeComplianceByResource_21626314;
          body: JsonNode): Recallable =
  ## describeComplianceByResource
  ## <p>Indicates whether the specified AWS resources are compliant. If a resource is noncompliant, this action returns the number of AWS Config rules that the resource does not comply with.</p> <p>A resource is compliant if it complies with all the AWS Config rules that evaluate it. It is noncompliant if it does not comply with one or more of these rules.</p> <p>If AWS Config has no current evaluation results for the resource, it returns <code>INSUFFICIENT_DATA</code>. This result might indicate one of the following conditions about the rules that evaluate the resource:</p> <ul> <li> <p>AWS Config has never invoked an evaluation for the rule. To check whether it has, use the <code>DescribeConfigRuleEvaluationStatus</code> action to get the <code>LastSuccessfulInvocationTime</code> and <code>LastFailedInvocationTime</code>.</p> </li> <li> <p>The rule's AWS Lambda function is failing to send evaluation results to AWS Config. Verify that the role that you assigned to your configuration recorder includes the <code>config:PutEvaluations</code> permission. If the rule is a custom rule, verify that the AWS Lambda execution role includes the <code>config:PutEvaluations</code> permission.</p> </li> <li> <p>The rule's AWS Lambda function has returned <code>NOT_APPLICABLE</code> for all evaluation results. This can occur if the resources were deleted or removed from the rule's scope.</p> </li> </ul>
  ##   body: JObject (required)
  var body_21626328 = newJObject()
  if body != nil:
    body_21626328 = body
  result = call_21626327.call(nil, nil, nil, nil, body_21626328)

var describeComplianceByResource* = Call_DescribeComplianceByResource_21626314(
    name: "describeComplianceByResource", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeComplianceByResource",
    validator: validate_DescribeComplianceByResource_21626315, base: "/",
    makeUrl: url_DescribeComplianceByResource_21626316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigRuleEvaluationStatus_21626329 = ref object of OpenApiRestCall_21625435
proc url_DescribeConfigRuleEvaluationStatus_21626331(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConfigRuleEvaluationStatus_21626330(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns status information for each of your AWS managed Config rules. The status includes information such as the last time AWS Config invoked the rule, the last time AWS Config failed to invoke the rule, and the related error for the last failure.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626332 = header.getOrDefault("X-Amz-Date")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Date", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Security-Token", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Target")
  valid_21626334 = validateParameter(valid_21626334, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConfigRuleEvaluationStatus"))
  if valid_21626334 != nil:
    section.add "X-Amz-Target", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Algorithm", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Signature")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Signature", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Credential")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Credential", valid_21626339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626341: Call_DescribeConfigRuleEvaluationStatus_21626329;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns status information for each of your AWS managed Config rules. The status includes information such as the last time AWS Config invoked the rule, the last time AWS Config failed to invoke the rule, and the related error for the last failure.
  ## 
  let valid = call_21626341.validator(path, query, header, formData, body, _)
  let scheme = call_21626341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626341.makeUrl(scheme.get, call_21626341.host, call_21626341.base,
                               call_21626341.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626341, uri, valid, _)

proc call*(call_21626342: Call_DescribeConfigRuleEvaluationStatus_21626329;
          body: JsonNode): Recallable =
  ## describeConfigRuleEvaluationStatus
  ## Returns status information for each of your AWS managed Config rules. The status includes information such as the last time AWS Config invoked the rule, the last time AWS Config failed to invoke the rule, and the related error for the last failure.
  ##   body: JObject (required)
  var body_21626343 = newJObject()
  if body != nil:
    body_21626343 = body
  result = call_21626342.call(nil, nil, nil, nil, body_21626343)

var describeConfigRuleEvaluationStatus* = Call_DescribeConfigRuleEvaluationStatus_21626329(
    name: "describeConfigRuleEvaluationStatus", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeConfigRuleEvaluationStatus",
    validator: validate_DescribeConfigRuleEvaluationStatus_21626330, base: "/",
    makeUrl: url_DescribeConfigRuleEvaluationStatus_21626331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigRules_21626344 = ref object of OpenApiRestCall_21625435
proc url_DescribeConfigRules_21626346(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConfigRules_21626345(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns details about your AWS Config rules.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626347 = header.getOrDefault("X-Amz-Date")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Date", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Security-Token", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Target")
  valid_21626349 = validateParameter(valid_21626349, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConfigRules"))
  if valid_21626349 != nil:
    section.add "X-Amz-Target", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Algorithm", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Signature")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Signature", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Credential")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Credential", valid_21626354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626356: Call_DescribeConfigRules_21626344; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns details about your AWS Config rules.
  ## 
  let valid = call_21626356.validator(path, query, header, formData, body, _)
  let scheme = call_21626356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626356.makeUrl(scheme.get, call_21626356.host, call_21626356.base,
                               call_21626356.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626356, uri, valid, _)

proc call*(call_21626357: Call_DescribeConfigRules_21626344; body: JsonNode): Recallable =
  ## describeConfigRules
  ## Returns details about your AWS Config rules.
  ##   body: JObject (required)
  var body_21626358 = newJObject()
  if body != nil:
    body_21626358 = body
  result = call_21626357.call(nil, nil, nil, nil, body_21626358)

var describeConfigRules* = Call_DescribeConfigRules_21626344(
    name: "describeConfigRules", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeConfigRules",
    validator: validate_DescribeConfigRules_21626345, base: "/",
    makeUrl: url_DescribeConfigRules_21626346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationAggregatorSourcesStatus_21626359 = ref object of OpenApiRestCall_21625435
proc url_DescribeConfigurationAggregatorSourcesStatus_21626361(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConfigurationAggregatorSourcesStatus_21626360(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Returns status information for sources within an aggregator. The status includes information about the last time AWS Config verified authorization between the source account and an aggregator account. In case of a failure, the status contains the related error code or message. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626362 = header.getOrDefault("X-Amz-Date")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Date", valid_21626362
  var valid_21626363 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "X-Amz-Security-Token", valid_21626363
  var valid_21626364 = header.getOrDefault("X-Amz-Target")
  valid_21626364 = validateParameter(valid_21626364, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConfigurationAggregatorSourcesStatus"))
  if valid_21626364 != nil:
    section.add "X-Amz-Target", valid_21626364
  var valid_21626365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Algorithm", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-Signature")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Signature", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Credential")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Credential", valid_21626369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626371: Call_DescribeConfigurationAggregatorSourcesStatus_21626359;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns status information for sources within an aggregator. The status includes information about the last time AWS Config verified authorization between the source account and an aggregator account. In case of a failure, the status contains the related error code or message. 
  ## 
  let valid = call_21626371.validator(path, query, header, formData, body, _)
  let scheme = call_21626371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626371.makeUrl(scheme.get, call_21626371.host, call_21626371.base,
                               call_21626371.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626371, uri, valid, _)

proc call*(call_21626372: Call_DescribeConfigurationAggregatorSourcesStatus_21626359;
          body: JsonNode): Recallable =
  ## describeConfigurationAggregatorSourcesStatus
  ## Returns status information for sources within an aggregator. The status includes information about the last time AWS Config verified authorization between the source account and an aggregator account. In case of a failure, the status contains the related error code or message. 
  ##   body: JObject (required)
  var body_21626373 = newJObject()
  if body != nil:
    body_21626373 = body
  result = call_21626372.call(nil, nil, nil, nil, body_21626373)

var describeConfigurationAggregatorSourcesStatus* = Call_DescribeConfigurationAggregatorSourcesStatus_21626359(
    name: "describeConfigurationAggregatorSourcesStatus",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeConfigurationAggregatorSourcesStatus",
    validator: validate_DescribeConfigurationAggregatorSourcesStatus_21626360,
    base: "/", makeUrl: url_DescribeConfigurationAggregatorSourcesStatus_21626361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationAggregators_21626374 = ref object of OpenApiRestCall_21625435
proc url_DescribeConfigurationAggregators_21626376(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConfigurationAggregators_21626375(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns the details of one or more configuration aggregators. If the configuration aggregator is not specified, this action returns the details for all the configuration aggregators associated with the account. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626377 = header.getOrDefault("X-Amz-Date")
  valid_21626377 = validateParameter(valid_21626377, JString, required = false,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "X-Amz-Date", valid_21626377
  var valid_21626378 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-Security-Token", valid_21626378
  var valid_21626379 = header.getOrDefault("X-Amz-Target")
  valid_21626379 = validateParameter(valid_21626379, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConfigurationAggregators"))
  if valid_21626379 != nil:
    section.add "X-Amz-Target", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-Algorithm", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Signature")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Signature", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Credential")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Credential", valid_21626384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626386: Call_DescribeConfigurationAggregators_21626374;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the details of one or more configuration aggregators. If the configuration aggregator is not specified, this action returns the details for all the configuration aggregators associated with the account. 
  ## 
  let valid = call_21626386.validator(path, query, header, formData, body, _)
  let scheme = call_21626386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626386.makeUrl(scheme.get, call_21626386.host, call_21626386.base,
                               call_21626386.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626386, uri, valid, _)

proc call*(call_21626387: Call_DescribeConfigurationAggregators_21626374;
          body: JsonNode): Recallable =
  ## describeConfigurationAggregators
  ## Returns the details of one or more configuration aggregators. If the configuration aggregator is not specified, this action returns the details for all the configuration aggregators associated with the account. 
  ##   body: JObject (required)
  var body_21626388 = newJObject()
  if body != nil:
    body_21626388 = body
  result = call_21626387.call(nil, nil, nil, nil, body_21626388)

var describeConfigurationAggregators* = Call_DescribeConfigurationAggregators_21626374(
    name: "describeConfigurationAggregators", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeConfigurationAggregators",
    validator: validate_DescribeConfigurationAggregators_21626375, base: "/",
    makeUrl: url_DescribeConfigurationAggregators_21626376,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationRecorderStatus_21626389 = ref object of OpenApiRestCall_21625435
proc url_DescribeConfigurationRecorderStatus_21626391(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConfigurationRecorderStatus_21626390(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns the current status of the specified configuration recorder. If a configuration recorder is not specified, this action returns the status of all configuration recorders associated with the account.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626392 = header.getOrDefault("X-Amz-Date")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Date", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-Security-Token", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Target")
  valid_21626394 = validateParameter(valid_21626394, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConfigurationRecorderStatus"))
  if valid_21626394 != nil:
    section.add "X-Amz-Target", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-Algorithm", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Signature")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Signature", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-Credential")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Credential", valid_21626399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626401: Call_DescribeConfigurationRecorderStatus_21626389;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the current status of the specified configuration recorder. If a configuration recorder is not specified, this action returns the status of all configuration recorders associated with the account.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> </note>
  ## 
  let valid = call_21626401.validator(path, query, header, formData, body, _)
  let scheme = call_21626401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626401.makeUrl(scheme.get, call_21626401.host, call_21626401.base,
                               call_21626401.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626401, uri, valid, _)

proc call*(call_21626402: Call_DescribeConfigurationRecorderStatus_21626389;
          body: JsonNode): Recallable =
  ## describeConfigurationRecorderStatus
  ## <p>Returns the current status of the specified configuration recorder. If a configuration recorder is not specified, this action returns the status of all configuration recorders associated with the account.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> </note>
  ##   body: JObject (required)
  var body_21626403 = newJObject()
  if body != nil:
    body_21626403 = body
  result = call_21626402.call(nil, nil, nil, nil, body_21626403)

var describeConfigurationRecorderStatus* = Call_DescribeConfigurationRecorderStatus_21626389(
    name: "describeConfigurationRecorderStatus", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeConfigurationRecorderStatus",
    validator: validate_DescribeConfigurationRecorderStatus_21626390, base: "/",
    makeUrl: url_DescribeConfigurationRecorderStatus_21626391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationRecorders_21626404 = ref object of OpenApiRestCall_21625435
proc url_DescribeConfigurationRecorders_21626406(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConfigurationRecorders_21626405(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns the details for the specified configuration recorders. If the configuration recorder is not specified, this action returns the details for all configuration recorders associated with the account.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626407 = header.getOrDefault("X-Amz-Date")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Date", valid_21626407
  var valid_21626408 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "X-Amz-Security-Token", valid_21626408
  var valid_21626409 = header.getOrDefault("X-Amz-Target")
  valid_21626409 = validateParameter(valid_21626409, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConfigurationRecorders"))
  if valid_21626409 != nil:
    section.add "X-Amz-Target", valid_21626409
  var valid_21626410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-Algorithm", valid_21626411
  var valid_21626412 = header.getOrDefault("X-Amz-Signature")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-Signature", valid_21626412
  var valid_21626413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626413 = validateParameter(valid_21626413, JString, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626413
  var valid_21626414 = header.getOrDefault("X-Amz-Credential")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "X-Amz-Credential", valid_21626414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626416: Call_DescribeConfigurationRecorders_21626404;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the details for the specified configuration recorders. If the configuration recorder is not specified, this action returns the details for all configuration recorders associated with the account.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> </note>
  ## 
  let valid = call_21626416.validator(path, query, header, formData, body, _)
  let scheme = call_21626416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626416.makeUrl(scheme.get, call_21626416.host, call_21626416.base,
                               call_21626416.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626416, uri, valid, _)

proc call*(call_21626417: Call_DescribeConfigurationRecorders_21626404;
          body: JsonNode): Recallable =
  ## describeConfigurationRecorders
  ## <p>Returns the details for the specified configuration recorders. If the configuration recorder is not specified, this action returns the details for all configuration recorders associated with the account.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> </note>
  ##   body: JObject (required)
  var body_21626418 = newJObject()
  if body != nil:
    body_21626418 = body
  result = call_21626417.call(nil, nil, nil, nil, body_21626418)

var describeConfigurationRecorders* = Call_DescribeConfigurationRecorders_21626404(
    name: "describeConfigurationRecorders", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeConfigurationRecorders",
    validator: validate_DescribeConfigurationRecorders_21626405, base: "/",
    makeUrl: url_DescribeConfigurationRecorders_21626406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConformancePackCompliance_21626419 = ref object of OpenApiRestCall_21625435
proc url_DescribeConformancePackCompliance_21626421(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConformancePackCompliance_21626420(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns compliance details for each rule in that conformance pack.</p> <note> <p>You must provide exact rule names.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626422 = header.getOrDefault("X-Amz-Date")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-Date", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-Security-Token", valid_21626423
  var valid_21626424 = header.getOrDefault("X-Amz-Target")
  valid_21626424 = validateParameter(valid_21626424, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConformancePackCompliance"))
  if valid_21626424 != nil:
    section.add "X-Amz-Target", valid_21626424
  var valid_21626425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626425 = validateParameter(valid_21626425, JString, required = false,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626425
  var valid_21626426 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626426 = validateParameter(valid_21626426, JString, required = false,
                                   default = nil)
  if valid_21626426 != nil:
    section.add "X-Amz-Algorithm", valid_21626426
  var valid_21626427 = header.getOrDefault("X-Amz-Signature")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-Signature", valid_21626427
  var valid_21626428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626428 = validateParameter(valid_21626428, JString, required = false,
                                   default = nil)
  if valid_21626428 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626428
  var valid_21626429 = header.getOrDefault("X-Amz-Credential")
  valid_21626429 = validateParameter(valid_21626429, JString, required = false,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "X-Amz-Credential", valid_21626429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626431: Call_DescribeConformancePackCompliance_21626419;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns compliance details for each rule in that conformance pack.</p> <note> <p>You must provide exact rule names.</p> </note>
  ## 
  let valid = call_21626431.validator(path, query, header, formData, body, _)
  let scheme = call_21626431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626431.makeUrl(scheme.get, call_21626431.host, call_21626431.base,
                               call_21626431.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626431, uri, valid, _)

proc call*(call_21626432: Call_DescribeConformancePackCompliance_21626419;
          body: JsonNode): Recallable =
  ## describeConformancePackCompliance
  ## <p>Returns compliance details for each rule in that conformance pack.</p> <note> <p>You must provide exact rule names.</p> </note>
  ##   body: JObject (required)
  var body_21626433 = newJObject()
  if body != nil:
    body_21626433 = body
  result = call_21626432.call(nil, nil, nil, nil, body_21626433)

var describeConformancePackCompliance* = Call_DescribeConformancePackCompliance_21626419(
    name: "describeConformancePackCompliance", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeConformancePackCompliance",
    validator: validate_DescribeConformancePackCompliance_21626420, base: "/",
    makeUrl: url_DescribeConformancePackCompliance_21626421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConformancePackStatus_21626434 = ref object of OpenApiRestCall_21625435
proc url_DescribeConformancePackStatus_21626436(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConformancePackStatus_21626435(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Provides one or more conformance packs deployment status.</p> <note> <p>If there are no conformance packs then you will see an empty result.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626437 = header.getOrDefault("X-Amz-Date")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Date", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Security-Token", valid_21626438
  var valid_21626439 = header.getOrDefault("X-Amz-Target")
  valid_21626439 = validateParameter(valid_21626439, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConformancePackStatus"))
  if valid_21626439 != nil:
    section.add "X-Amz-Target", valid_21626439
  var valid_21626440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626440
  var valid_21626441 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626441 = validateParameter(valid_21626441, JString, required = false,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "X-Amz-Algorithm", valid_21626441
  var valid_21626442 = header.getOrDefault("X-Amz-Signature")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-Signature", valid_21626442
  var valid_21626443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626443 = validateParameter(valid_21626443, JString, required = false,
                                   default = nil)
  if valid_21626443 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626443
  var valid_21626444 = header.getOrDefault("X-Amz-Credential")
  valid_21626444 = validateParameter(valid_21626444, JString, required = false,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "X-Amz-Credential", valid_21626444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626446: Call_DescribeConformancePackStatus_21626434;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Provides one or more conformance packs deployment status.</p> <note> <p>If there are no conformance packs then you will see an empty result.</p> </note>
  ## 
  let valid = call_21626446.validator(path, query, header, formData, body, _)
  let scheme = call_21626446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626446.makeUrl(scheme.get, call_21626446.host, call_21626446.base,
                               call_21626446.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626446, uri, valid, _)

proc call*(call_21626447: Call_DescribeConformancePackStatus_21626434;
          body: JsonNode): Recallable =
  ## describeConformancePackStatus
  ## <p>Provides one or more conformance packs deployment status.</p> <note> <p>If there are no conformance packs then you will see an empty result.</p> </note>
  ##   body: JObject (required)
  var body_21626448 = newJObject()
  if body != nil:
    body_21626448 = body
  result = call_21626447.call(nil, nil, nil, nil, body_21626448)

var describeConformancePackStatus* = Call_DescribeConformancePackStatus_21626434(
    name: "describeConformancePackStatus", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeConformancePackStatus",
    validator: validate_DescribeConformancePackStatus_21626435, base: "/",
    makeUrl: url_DescribeConformancePackStatus_21626436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConformancePacks_21626449 = ref object of OpenApiRestCall_21625435
proc url_DescribeConformancePacks_21626451(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConformancePacks_21626450(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of one or more conformance packs.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626452 = header.getOrDefault("X-Amz-Date")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Date", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-Security-Token", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-Target")
  valid_21626454 = validateParameter(valid_21626454, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConformancePacks"))
  if valid_21626454 != nil:
    section.add "X-Amz-Target", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-Algorithm", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Signature")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Signature", valid_21626457
  var valid_21626458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626458 = validateParameter(valid_21626458, JString, required = false,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626458
  var valid_21626459 = header.getOrDefault("X-Amz-Credential")
  valid_21626459 = validateParameter(valid_21626459, JString, required = false,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "X-Amz-Credential", valid_21626459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626461: Call_DescribeConformancePacks_21626449;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of one or more conformance packs.
  ## 
  let valid = call_21626461.validator(path, query, header, formData, body, _)
  let scheme = call_21626461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626461.makeUrl(scheme.get, call_21626461.host, call_21626461.base,
                               call_21626461.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626461, uri, valid, _)

proc call*(call_21626462: Call_DescribeConformancePacks_21626449; body: JsonNode): Recallable =
  ## describeConformancePacks
  ## Returns a list of one or more conformance packs.
  ##   body: JObject (required)
  var body_21626463 = newJObject()
  if body != nil:
    body_21626463 = body
  result = call_21626462.call(nil, nil, nil, nil, body_21626463)

var describeConformancePacks* = Call_DescribeConformancePacks_21626449(
    name: "describeConformancePacks", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeConformancePacks",
    validator: validate_DescribeConformancePacks_21626450, base: "/",
    makeUrl: url_DescribeConformancePacks_21626451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDeliveryChannelStatus_21626464 = ref object of OpenApiRestCall_21625435
proc url_DescribeDeliveryChannelStatus_21626466(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDeliveryChannelStatus_21626465(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns the current status of the specified delivery channel. If a delivery channel is not specified, this action returns the current status of all delivery channels associated with the account.</p> <note> <p>Currently, you can specify only one delivery channel per region in your account.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626467 = header.getOrDefault("X-Amz-Date")
  valid_21626467 = validateParameter(valid_21626467, JString, required = false,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "X-Amz-Date", valid_21626467
  var valid_21626468 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "X-Amz-Security-Token", valid_21626468
  var valid_21626469 = header.getOrDefault("X-Amz-Target")
  valid_21626469 = validateParameter(valid_21626469, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeDeliveryChannelStatus"))
  if valid_21626469 != nil:
    section.add "X-Amz-Target", valid_21626469
  var valid_21626470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-Algorithm", valid_21626471
  var valid_21626472 = header.getOrDefault("X-Amz-Signature")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Signature", valid_21626472
  var valid_21626473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-Credential")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Credential", valid_21626474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626476: Call_DescribeDeliveryChannelStatus_21626464;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the current status of the specified delivery channel. If a delivery channel is not specified, this action returns the current status of all delivery channels associated with the account.</p> <note> <p>Currently, you can specify only one delivery channel per region in your account.</p> </note>
  ## 
  let valid = call_21626476.validator(path, query, header, formData, body, _)
  let scheme = call_21626476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626476.makeUrl(scheme.get, call_21626476.host, call_21626476.base,
                               call_21626476.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626476, uri, valid, _)

proc call*(call_21626477: Call_DescribeDeliveryChannelStatus_21626464;
          body: JsonNode): Recallable =
  ## describeDeliveryChannelStatus
  ## <p>Returns the current status of the specified delivery channel. If a delivery channel is not specified, this action returns the current status of all delivery channels associated with the account.</p> <note> <p>Currently, you can specify only one delivery channel per region in your account.</p> </note>
  ##   body: JObject (required)
  var body_21626478 = newJObject()
  if body != nil:
    body_21626478 = body
  result = call_21626477.call(nil, nil, nil, nil, body_21626478)

var describeDeliveryChannelStatus* = Call_DescribeDeliveryChannelStatus_21626464(
    name: "describeDeliveryChannelStatus", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeDeliveryChannelStatus",
    validator: validate_DescribeDeliveryChannelStatus_21626465, base: "/",
    makeUrl: url_DescribeDeliveryChannelStatus_21626466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDeliveryChannels_21626479 = ref object of OpenApiRestCall_21625435
proc url_DescribeDeliveryChannels_21626481(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDeliveryChannels_21626480(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns details about the specified delivery channel. If a delivery channel is not specified, this action returns the details of all delivery channels associated with the account.</p> <note> <p>Currently, you can specify only one delivery channel per region in your account.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626482 = header.getOrDefault("X-Amz-Date")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-Date", valid_21626482
  var valid_21626483 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "X-Amz-Security-Token", valid_21626483
  var valid_21626484 = header.getOrDefault("X-Amz-Target")
  valid_21626484 = validateParameter(valid_21626484, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeDeliveryChannels"))
  if valid_21626484 != nil:
    section.add "X-Amz-Target", valid_21626484
  var valid_21626485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626485
  var valid_21626486 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626486 = validateParameter(valid_21626486, JString, required = false,
                                   default = nil)
  if valid_21626486 != nil:
    section.add "X-Amz-Algorithm", valid_21626486
  var valid_21626487 = header.getOrDefault("X-Amz-Signature")
  valid_21626487 = validateParameter(valid_21626487, JString, required = false,
                                   default = nil)
  if valid_21626487 != nil:
    section.add "X-Amz-Signature", valid_21626487
  var valid_21626488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626488
  var valid_21626489 = header.getOrDefault("X-Amz-Credential")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-Credential", valid_21626489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626491: Call_DescribeDeliveryChannels_21626479;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns details about the specified delivery channel. If a delivery channel is not specified, this action returns the details of all delivery channels associated with the account.</p> <note> <p>Currently, you can specify only one delivery channel per region in your account.</p> </note>
  ## 
  let valid = call_21626491.validator(path, query, header, formData, body, _)
  let scheme = call_21626491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626491.makeUrl(scheme.get, call_21626491.host, call_21626491.base,
                               call_21626491.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626491, uri, valid, _)

proc call*(call_21626492: Call_DescribeDeliveryChannels_21626479; body: JsonNode): Recallable =
  ## describeDeliveryChannels
  ## <p>Returns details about the specified delivery channel. If a delivery channel is not specified, this action returns the details of all delivery channels associated with the account.</p> <note> <p>Currently, you can specify only one delivery channel per region in your account.</p> </note>
  ##   body: JObject (required)
  var body_21626493 = newJObject()
  if body != nil:
    body_21626493 = body
  result = call_21626492.call(nil, nil, nil, nil, body_21626493)

var describeDeliveryChannels* = Call_DescribeDeliveryChannels_21626479(
    name: "describeDeliveryChannels", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeDeliveryChannels",
    validator: validate_DescribeDeliveryChannels_21626480, base: "/",
    makeUrl: url_DescribeDeliveryChannels_21626481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrganizationConfigRuleStatuses_21626494 = ref object of OpenApiRestCall_21625435
proc url_DescribeOrganizationConfigRuleStatuses_21626496(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeOrganizationConfigRuleStatuses_21626495(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Provides organization config rule deployment status for an organization.</p> <note> <p>The status is not considered successful until organization config rule is successfully deployed in all the member accounts with an exception of excluded accounts.</p> <p>When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization config rule names. It is only applicable, when you request all the organization config rules.</p> <p>Only a master account can call this API.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626497 = header.getOrDefault("X-Amz-Date")
  valid_21626497 = validateParameter(valid_21626497, JString, required = false,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "X-Amz-Date", valid_21626497
  var valid_21626498 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626498 = validateParameter(valid_21626498, JString, required = false,
                                   default = nil)
  if valid_21626498 != nil:
    section.add "X-Amz-Security-Token", valid_21626498
  var valid_21626499 = header.getOrDefault("X-Amz-Target")
  valid_21626499 = validateParameter(valid_21626499, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeOrganizationConfigRuleStatuses"))
  if valid_21626499 != nil:
    section.add "X-Amz-Target", valid_21626499
  var valid_21626500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626500 = validateParameter(valid_21626500, JString, required = false,
                                   default = nil)
  if valid_21626500 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626500
  var valid_21626501 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626501 = validateParameter(valid_21626501, JString, required = false,
                                   default = nil)
  if valid_21626501 != nil:
    section.add "X-Amz-Algorithm", valid_21626501
  var valid_21626502 = header.getOrDefault("X-Amz-Signature")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Signature", valid_21626502
  var valid_21626503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626503 = validateParameter(valid_21626503, JString, required = false,
                                   default = nil)
  if valid_21626503 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626503
  var valid_21626504 = header.getOrDefault("X-Amz-Credential")
  valid_21626504 = validateParameter(valid_21626504, JString, required = false,
                                   default = nil)
  if valid_21626504 != nil:
    section.add "X-Amz-Credential", valid_21626504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626506: Call_DescribeOrganizationConfigRuleStatuses_21626494;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Provides organization config rule deployment status for an organization.</p> <note> <p>The status is not considered successful until organization config rule is successfully deployed in all the member accounts with an exception of excluded accounts.</p> <p>When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization config rule names. It is only applicable, when you request all the organization config rules.</p> <p>Only a master account can call this API.</p> </note>
  ## 
  let valid = call_21626506.validator(path, query, header, formData, body, _)
  let scheme = call_21626506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626506.makeUrl(scheme.get, call_21626506.host, call_21626506.base,
                               call_21626506.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626506, uri, valid, _)

proc call*(call_21626507: Call_DescribeOrganizationConfigRuleStatuses_21626494;
          body: JsonNode): Recallable =
  ## describeOrganizationConfigRuleStatuses
  ## <p>Provides organization config rule deployment status for an organization.</p> <note> <p>The status is not considered successful until organization config rule is successfully deployed in all the member accounts with an exception of excluded accounts.</p> <p>When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization config rule names. It is only applicable, when you request all the organization config rules.</p> <p>Only a master account can call this API.</p> </note>
  ##   body: JObject (required)
  var body_21626508 = newJObject()
  if body != nil:
    body_21626508 = body
  result = call_21626507.call(nil, nil, nil, nil, body_21626508)

var describeOrganizationConfigRuleStatuses* = Call_DescribeOrganizationConfigRuleStatuses_21626494(
    name: "describeOrganizationConfigRuleStatuses", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeOrganizationConfigRuleStatuses",
    validator: validate_DescribeOrganizationConfigRuleStatuses_21626495,
    base: "/", makeUrl: url_DescribeOrganizationConfigRuleStatuses_21626496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrganizationConfigRules_21626509 = ref object of OpenApiRestCall_21625435
proc url_DescribeOrganizationConfigRules_21626511(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeOrganizationConfigRules_21626510(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns a list of organization config rules.</p> <note> <p>When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization config rule names. It is only applicable, when you request all the organization config rules.</p> <p>Only a master account can call this API.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626512 = header.getOrDefault("X-Amz-Date")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Date", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-Security-Token", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-Target")
  valid_21626514 = validateParameter(valid_21626514, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeOrganizationConfigRules"))
  if valid_21626514 != nil:
    section.add "X-Amz-Target", valid_21626514
  var valid_21626515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626515 = validateParameter(valid_21626515, JString, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626515
  var valid_21626516 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-Algorithm", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-Signature")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-Signature", valid_21626517
  var valid_21626518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626518 = validateParameter(valid_21626518, JString, required = false,
                                   default = nil)
  if valid_21626518 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626518
  var valid_21626519 = header.getOrDefault("X-Amz-Credential")
  valid_21626519 = validateParameter(valid_21626519, JString, required = false,
                                   default = nil)
  if valid_21626519 != nil:
    section.add "X-Amz-Credential", valid_21626519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626521: Call_DescribeOrganizationConfigRules_21626509;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of organization config rules.</p> <note> <p>When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization config rule names. It is only applicable, when you request all the organization config rules.</p> <p>Only a master account can call this API.</p> </note>
  ## 
  let valid = call_21626521.validator(path, query, header, formData, body, _)
  let scheme = call_21626521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626521.makeUrl(scheme.get, call_21626521.host, call_21626521.base,
                               call_21626521.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626521, uri, valid, _)

proc call*(call_21626522: Call_DescribeOrganizationConfigRules_21626509;
          body: JsonNode): Recallable =
  ## describeOrganizationConfigRules
  ## <p>Returns a list of organization config rules.</p> <note> <p>When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization config rule names. It is only applicable, when you request all the organization config rules.</p> <p>Only a master account can call this API.</p> </note>
  ##   body: JObject (required)
  var body_21626523 = newJObject()
  if body != nil:
    body_21626523 = body
  result = call_21626522.call(nil, nil, nil, nil, body_21626523)

var describeOrganizationConfigRules* = Call_DescribeOrganizationConfigRules_21626509(
    name: "describeOrganizationConfigRules", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeOrganizationConfigRules",
    validator: validate_DescribeOrganizationConfigRules_21626510, base: "/",
    makeUrl: url_DescribeOrganizationConfigRules_21626511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrganizationConformancePackStatuses_21626524 = ref object of OpenApiRestCall_21625435
proc url_DescribeOrganizationConformancePackStatuses_21626526(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeOrganizationConformancePackStatuses_21626525(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Provides organization conformance pack deployment status for an organization.</p> <note> <p>The status is not considered successful until organization conformance pack is successfully deployed in all the member accounts with an exception of excluded accounts.</p> <p>When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization conformance pack names. They are only applicable, when you request all the organization conformance packs.</p> <p>Only a master account can call this API.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626527 = header.getOrDefault("X-Amz-Date")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "X-Amz-Date", valid_21626527
  var valid_21626528 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626528 = validateParameter(valid_21626528, JString, required = false,
                                   default = nil)
  if valid_21626528 != nil:
    section.add "X-Amz-Security-Token", valid_21626528
  var valid_21626529 = header.getOrDefault("X-Amz-Target")
  valid_21626529 = validateParameter(valid_21626529, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeOrganizationConformancePackStatuses"))
  if valid_21626529 != nil:
    section.add "X-Amz-Target", valid_21626529
  var valid_21626530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626530 = validateParameter(valid_21626530, JString, required = false,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626530
  var valid_21626531 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626531 = validateParameter(valid_21626531, JString, required = false,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "X-Amz-Algorithm", valid_21626531
  var valid_21626532 = header.getOrDefault("X-Amz-Signature")
  valid_21626532 = validateParameter(valid_21626532, JString, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "X-Amz-Signature", valid_21626532
  var valid_21626533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626533 = validateParameter(valid_21626533, JString, required = false,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626533
  var valid_21626534 = header.getOrDefault("X-Amz-Credential")
  valid_21626534 = validateParameter(valid_21626534, JString, required = false,
                                   default = nil)
  if valid_21626534 != nil:
    section.add "X-Amz-Credential", valid_21626534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626536: Call_DescribeOrganizationConformancePackStatuses_21626524;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Provides organization conformance pack deployment status for an organization.</p> <note> <p>The status is not considered successful until organization conformance pack is successfully deployed in all the member accounts with an exception of excluded accounts.</p> <p>When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization conformance pack names. They are only applicable, when you request all the organization conformance packs.</p> <p>Only a master account can call this API.</p> </note>
  ## 
  let valid = call_21626536.validator(path, query, header, formData, body, _)
  let scheme = call_21626536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626536.makeUrl(scheme.get, call_21626536.host, call_21626536.base,
                               call_21626536.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626536, uri, valid, _)

proc call*(call_21626537: Call_DescribeOrganizationConformancePackStatuses_21626524;
          body: JsonNode): Recallable =
  ## describeOrganizationConformancePackStatuses
  ## <p>Provides organization conformance pack deployment status for an organization.</p> <note> <p>The status is not considered successful until organization conformance pack is successfully deployed in all the member accounts with an exception of excluded accounts.</p> <p>When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization conformance pack names. They are only applicable, when you request all the organization conformance packs.</p> <p>Only a master account can call this API.</p> </note>
  ##   body: JObject (required)
  var body_21626538 = newJObject()
  if body != nil:
    body_21626538 = body
  result = call_21626537.call(nil, nil, nil, nil, body_21626538)

var describeOrganizationConformancePackStatuses* = Call_DescribeOrganizationConformancePackStatuses_21626524(
    name: "describeOrganizationConformancePackStatuses",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeOrganizationConformancePackStatuses",
    validator: validate_DescribeOrganizationConformancePackStatuses_21626525,
    base: "/", makeUrl: url_DescribeOrganizationConformancePackStatuses_21626526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrganizationConformancePacks_21626539 = ref object of OpenApiRestCall_21625435
proc url_DescribeOrganizationConformancePacks_21626541(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeOrganizationConformancePacks_21626540(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns a list of organization conformance packs.</p> <note> <p>When you specify the limit and the next token, you receive a paginated response. </p> <p>Limit and next token are not applicable if you specify organization conformance packs names. They are only applicable, when you request all the organization conformance packs. </p> <p>Only a master account can call this API.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626542 = header.getOrDefault("X-Amz-Date")
  valid_21626542 = validateParameter(valid_21626542, JString, required = false,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "X-Amz-Date", valid_21626542
  var valid_21626543 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "X-Amz-Security-Token", valid_21626543
  var valid_21626544 = header.getOrDefault("X-Amz-Target")
  valid_21626544 = validateParameter(valid_21626544, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeOrganizationConformancePacks"))
  if valid_21626544 != nil:
    section.add "X-Amz-Target", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-Algorithm", valid_21626546
  var valid_21626547 = header.getOrDefault("X-Amz-Signature")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-Signature", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626548
  var valid_21626549 = header.getOrDefault("X-Amz-Credential")
  valid_21626549 = validateParameter(valid_21626549, JString, required = false,
                                   default = nil)
  if valid_21626549 != nil:
    section.add "X-Amz-Credential", valid_21626549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626551: Call_DescribeOrganizationConformancePacks_21626539;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of organization conformance packs.</p> <note> <p>When you specify the limit and the next token, you receive a paginated response. </p> <p>Limit and next token are not applicable if you specify organization conformance packs names. They are only applicable, when you request all the organization conformance packs. </p> <p>Only a master account can call this API.</p> </note>
  ## 
  let valid = call_21626551.validator(path, query, header, formData, body, _)
  let scheme = call_21626551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626551.makeUrl(scheme.get, call_21626551.host, call_21626551.base,
                               call_21626551.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626551, uri, valid, _)

proc call*(call_21626552: Call_DescribeOrganizationConformancePacks_21626539;
          body: JsonNode): Recallable =
  ## describeOrganizationConformancePacks
  ## <p>Returns a list of organization conformance packs.</p> <note> <p>When you specify the limit and the next token, you receive a paginated response. </p> <p>Limit and next token are not applicable if you specify organization conformance packs names. They are only applicable, when you request all the organization conformance packs. </p> <p>Only a master account can call this API.</p> </note>
  ##   body: JObject (required)
  var body_21626553 = newJObject()
  if body != nil:
    body_21626553 = body
  result = call_21626552.call(nil, nil, nil, nil, body_21626553)

var describeOrganizationConformancePacks* = Call_DescribeOrganizationConformancePacks_21626539(
    name: "describeOrganizationConformancePacks", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeOrganizationConformancePacks",
    validator: validate_DescribeOrganizationConformancePacks_21626540, base: "/",
    makeUrl: url_DescribeOrganizationConformancePacks_21626541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePendingAggregationRequests_21626554 = ref object of OpenApiRestCall_21625435
proc url_DescribePendingAggregationRequests_21626556(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePendingAggregationRequests_21626555(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns a list of all pending aggregation requests.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626557 = header.getOrDefault("X-Amz-Date")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "X-Amz-Date", valid_21626557
  var valid_21626558 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "X-Amz-Security-Token", valid_21626558
  var valid_21626559 = header.getOrDefault("X-Amz-Target")
  valid_21626559 = validateParameter(valid_21626559, JString, required = true, default = newJString(
      "StarlingDoveService.DescribePendingAggregationRequests"))
  if valid_21626559 != nil:
    section.add "X-Amz-Target", valid_21626559
  var valid_21626560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626560
  var valid_21626561 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "X-Amz-Algorithm", valid_21626561
  var valid_21626562 = header.getOrDefault("X-Amz-Signature")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "X-Amz-Signature", valid_21626562
  var valid_21626563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626563
  var valid_21626564 = header.getOrDefault("X-Amz-Credential")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "X-Amz-Credential", valid_21626564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626566: Call_DescribePendingAggregationRequests_21626554;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of all pending aggregation requests.
  ## 
  let valid = call_21626566.validator(path, query, header, formData, body, _)
  let scheme = call_21626566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626566.makeUrl(scheme.get, call_21626566.host, call_21626566.base,
                               call_21626566.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626566, uri, valid, _)

proc call*(call_21626567: Call_DescribePendingAggregationRequests_21626554;
          body: JsonNode): Recallable =
  ## describePendingAggregationRequests
  ## Returns a list of all pending aggregation requests.
  ##   body: JObject (required)
  var body_21626568 = newJObject()
  if body != nil:
    body_21626568 = body
  result = call_21626567.call(nil, nil, nil, nil, body_21626568)

var describePendingAggregationRequests* = Call_DescribePendingAggregationRequests_21626554(
    name: "describePendingAggregationRequests", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribePendingAggregationRequests",
    validator: validate_DescribePendingAggregationRequests_21626555, base: "/",
    makeUrl: url_DescribePendingAggregationRequests_21626556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRemediationConfigurations_21626569 = ref object of OpenApiRestCall_21625435
proc url_DescribeRemediationConfigurations_21626571(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRemediationConfigurations_21626570(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns the details of one or more remediation configurations.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626572 = header.getOrDefault("X-Amz-Date")
  valid_21626572 = validateParameter(valid_21626572, JString, required = false,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "X-Amz-Date", valid_21626572
  var valid_21626573 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626573 = validateParameter(valid_21626573, JString, required = false,
                                   default = nil)
  if valid_21626573 != nil:
    section.add "X-Amz-Security-Token", valid_21626573
  var valid_21626574 = header.getOrDefault("X-Amz-Target")
  valid_21626574 = validateParameter(valid_21626574, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeRemediationConfigurations"))
  if valid_21626574 != nil:
    section.add "X-Amz-Target", valid_21626574
  var valid_21626575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626575 = validateParameter(valid_21626575, JString, required = false,
                                   default = nil)
  if valid_21626575 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626575
  var valid_21626576 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626576 = validateParameter(valid_21626576, JString, required = false,
                                   default = nil)
  if valid_21626576 != nil:
    section.add "X-Amz-Algorithm", valid_21626576
  var valid_21626577 = header.getOrDefault("X-Amz-Signature")
  valid_21626577 = validateParameter(valid_21626577, JString, required = false,
                                   default = nil)
  if valid_21626577 != nil:
    section.add "X-Amz-Signature", valid_21626577
  var valid_21626578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626578
  var valid_21626579 = header.getOrDefault("X-Amz-Credential")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-Credential", valid_21626579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626581: Call_DescribeRemediationConfigurations_21626569;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the details of one or more remediation configurations.
  ## 
  let valid = call_21626581.validator(path, query, header, formData, body, _)
  let scheme = call_21626581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626581.makeUrl(scheme.get, call_21626581.host, call_21626581.base,
                               call_21626581.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626581, uri, valid, _)

proc call*(call_21626582: Call_DescribeRemediationConfigurations_21626569;
          body: JsonNode): Recallable =
  ## describeRemediationConfigurations
  ## Returns the details of one or more remediation configurations.
  ##   body: JObject (required)
  var body_21626583 = newJObject()
  if body != nil:
    body_21626583 = body
  result = call_21626582.call(nil, nil, nil, nil, body_21626583)

var describeRemediationConfigurations* = Call_DescribeRemediationConfigurations_21626569(
    name: "describeRemediationConfigurations", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeRemediationConfigurations",
    validator: validate_DescribeRemediationConfigurations_21626570, base: "/",
    makeUrl: url_DescribeRemediationConfigurations_21626571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRemediationExceptions_21626584 = ref object of OpenApiRestCall_21625435
proc url_DescribeRemediationExceptions_21626586(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRemediationExceptions_21626585(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns the details of one or more remediation exceptions. A detailed view of a remediation exception for a set of resources that includes an explanation of an exception and the time when the exception will be deleted. When you specify the limit and the next token, you receive a paginated response. </p> <note> <p>When you specify the limit and the next token, you receive a paginated response. </p> <p>Limit and next token are not applicable if you request resources in batch. It is only applicable, when you request all resources.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626587 = query.getOrDefault("Limit")
  valid_21626587 = validateParameter(valid_21626587, JString, required = false,
                                   default = nil)
  if valid_21626587 != nil:
    section.add "Limit", valid_21626587
  var valid_21626588 = query.getOrDefault("NextToken")
  valid_21626588 = validateParameter(valid_21626588, JString, required = false,
                                   default = nil)
  if valid_21626588 != nil:
    section.add "NextToken", valid_21626588
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626589 = header.getOrDefault("X-Amz-Date")
  valid_21626589 = validateParameter(valid_21626589, JString, required = false,
                                   default = nil)
  if valid_21626589 != nil:
    section.add "X-Amz-Date", valid_21626589
  var valid_21626590 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626590 = validateParameter(valid_21626590, JString, required = false,
                                   default = nil)
  if valid_21626590 != nil:
    section.add "X-Amz-Security-Token", valid_21626590
  var valid_21626591 = header.getOrDefault("X-Amz-Target")
  valid_21626591 = validateParameter(valid_21626591, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeRemediationExceptions"))
  if valid_21626591 != nil:
    section.add "X-Amz-Target", valid_21626591
  var valid_21626592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626592 = validateParameter(valid_21626592, JString, required = false,
                                   default = nil)
  if valid_21626592 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626592
  var valid_21626593 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626593 = validateParameter(valid_21626593, JString, required = false,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "X-Amz-Algorithm", valid_21626593
  var valid_21626594 = header.getOrDefault("X-Amz-Signature")
  valid_21626594 = validateParameter(valid_21626594, JString, required = false,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "X-Amz-Signature", valid_21626594
  var valid_21626595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626595 = validateParameter(valid_21626595, JString, required = false,
                                   default = nil)
  if valid_21626595 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626595
  var valid_21626596 = header.getOrDefault("X-Amz-Credential")
  valid_21626596 = validateParameter(valid_21626596, JString, required = false,
                                   default = nil)
  if valid_21626596 != nil:
    section.add "X-Amz-Credential", valid_21626596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626598: Call_DescribeRemediationExceptions_21626584;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the details of one or more remediation exceptions. A detailed view of a remediation exception for a set of resources that includes an explanation of an exception and the time when the exception will be deleted. When you specify the limit and the next token, you receive a paginated response. </p> <note> <p>When you specify the limit and the next token, you receive a paginated response. </p> <p>Limit and next token are not applicable if you request resources in batch. It is only applicable, when you request all resources.</p> </note>
  ## 
  let valid = call_21626598.validator(path, query, header, formData, body, _)
  let scheme = call_21626598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626598.makeUrl(scheme.get, call_21626598.host, call_21626598.base,
                               call_21626598.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626598, uri, valid, _)

proc call*(call_21626599: Call_DescribeRemediationExceptions_21626584;
          body: JsonNode; Limit: string = ""; NextToken: string = ""): Recallable =
  ## describeRemediationExceptions
  ## <p>Returns the details of one or more remediation exceptions. A detailed view of a remediation exception for a set of resources that includes an explanation of an exception and the time when the exception will be deleted. When you specify the limit and the next token, you receive a paginated response. </p> <note> <p>When you specify the limit and the next token, you receive a paginated response. </p> <p>Limit and next token are not applicable if you request resources in batch. It is only applicable, when you request all resources.</p> </note>
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626601 = newJObject()
  var body_21626602 = newJObject()
  add(query_21626601, "Limit", newJString(Limit))
  add(query_21626601, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626602 = body
  result = call_21626599.call(nil, query_21626601, nil, nil, body_21626602)

var describeRemediationExceptions* = Call_DescribeRemediationExceptions_21626584(
    name: "describeRemediationExceptions", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeRemediationExceptions",
    validator: validate_DescribeRemediationExceptions_21626585, base: "/",
    makeUrl: url_DescribeRemediationExceptions_21626586,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRemediationExecutionStatus_21626606 = ref object of OpenApiRestCall_21625435
proc url_DescribeRemediationExecutionStatus_21626608(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRemediationExecutionStatus_21626607(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Provides a detailed view of a Remediation Execution for a set of resources including state, timestamps for when steps for the remediation execution occur, and any error messages for steps that have failed. When you specify the limit and the next token, you receive a paginated response.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626609 = query.getOrDefault("Limit")
  valid_21626609 = validateParameter(valid_21626609, JString, required = false,
                                   default = nil)
  if valid_21626609 != nil:
    section.add "Limit", valid_21626609
  var valid_21626610 = query.getOrDefault("NextToken")
  valid_21626610 = validateParameter(valid_21626610, JString, required = false,
                                   default = nil)
  if valid_21626610 != nil:
    section.add "NextToken", valid_21626610
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626611 = header.getOrDefault("X-Amz-Date")
  valid_21626611 = validateParameter(valid_21626611, JString, required = false,
                                   default = nil)
  if valid_21626611 != nil:
    section.add "X-Amz-Date", valid_21626611
  var valid_21626612 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626612 = validateParameter(valid_21626612, JString, required = false,
                                   default = nil)
  if valid_21626612 != nil:
    section.add "X-Amz-Security-Token", valid_21626612
  var valid_21626613 = header.getOrDefault("X-Amz-Target")
  valid_21626613 = validateParameter(valid_21626613, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeRemediationExecutionStatus"))
  if valid_21626613 != nil:
    section.add "X-Amz-Target", valid_21626613
  var valid_21626614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626614 = validateParameter(valid_21626614, JString, required = false,
                                   default = nil)
  if valid_21626614 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626614
  var valid_21626615 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626615 = validateParameter(valid_21626615, JString, required = false,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "X-Amz-Algorithm", valid_21626615
  var valid_21626616 = header.getOrDefault("X-Amz-Signature")
  valid_21626616 = validateParameter(valid_21626616, JString, required = false,
                                   default = nil)
  if valid_21626616 != nil:
    section.add "X-Amz-Signature", valid_21626616
  var valid_21626617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-Credential")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-Credential", valid_21626618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626620: Call_DescribeRemediationExecutionStatus_21626606;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides a detailed view of a Remediation Execution for a set of resources including state, timestamps for when steps for the remediation execution occur, and any error messages for steps that have failed. When you specify the limit and the next token, you receive a paginated response.
  ## 
  let valid = call_21626620.validator(path, query, header, formData, body, _)
  let scheme = call_21626620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626620.makeUrl(scheme.get, call_21626620.host, call_21626620.base,
                               call_21626620.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626620, uri, valid, _)

proc call*(call_21626621: Call_DescribeRemediationExecutionStatus_21626606;
          body: JsonNode; Limit: string = ""; NextToken: string = ""): Recallable =
  ## describeRemediationExecutionStatus
  ## Provides a detailed view of a Remediation Execution for a set of resources including state, timestamps for when steps for the remediation execution occur, and any error messages for steps that have failed. When you specify the limit and the next token, you receive a paginated response.
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626622 = newJObject()
  var body_21626623 = newJObject()
  add(query_21626622, "Limit", newJString(Limit))
  add(query_21626622, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626623 = body
  result = call_21626621.call(nil, query_21626622, nil, nil, body_21626623)

var describeRemediationExecutionStatus* = Call_DescribeRemediationExecutionStatus_21626606(
    name: "describeRemediationExecutionStatus", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeRemediationExecutionStatus",
    validator: validate_DescribeRemediationExecutionStatus_21626607, base: "/",
    makeUrl: url_DescribeRemediationExecutionStatus_21626608,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRetentionConfigurations_21626624 = ref object of OpenApiRestCall_21625435
proc url_DescribeRetentionConfigurations_21626626(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRetentionConfigurations_21626625(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns the details of one or more retention configurations. If the retention configuration name is not specified, this action returns the details for all the retention configurations for that account.</p> <note> <p>Currently, AWS Config supports only one retention configuration per region in your account.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626627 = header.getOrDefault("X-Amz-Date")
  valid_21626627 = validateParameter(valid_21626627, JString, required = false,
                                   default = nil)
  if valid_21626627 != nil:
    section.add "X-Amz-Date", valid_21626627
  var valid_21626628 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626628 = validateParameter(valid_21626628, JString, required = false,
                                   default = nil)
  if valid_21626628 != nil:
    section.add "X-Amz-Security-Token", valid_21626628
  var valid_21626629 = header.getOrDefault("X-Amz-Target")
  valid_21626629 = validateParameter(valid_21626629, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeRetentionConfigurations"))
  if valid_21626629 != nil:
    section.add "X-Amz-Target", valid_21626629
  var valid_21626630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626630 = validateParameter(valid_21626630, JString, required = false,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626630
  var valid_21626631 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "X-Amz-Algorithm", valid_21626631
  var valid_21626632 = header.getOrDefault("X-Amz-Signature")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-Signature", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626633
  var valid_21626634 = header.getOrDefault("X-Amz-Credential")
  valid_21626634 = validateParameter(valid_21626634, JString, required = false,
                                   default = nil)
  if valid_21626634 != nil:
    section.add "X-Amz-Credential", valid_21626634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626636: Call_DescribeRetentionConfigurations_21626624;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the details of one or more retention configurations. If the retention configuration name is not specified, this action returns the details for all the retention configurations for that account.</p> <note> <p>Currently, AWS Config supports only one retention configuration per region in your account.</p> </note>
  ## 
  let valid = call_21626636.validator(path, query, header, formData, body, _)
  let scheme = call_21626636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626636.makeUrl(scheme.get, call_21626636.host, call_21626636.base,
                               call_21626636.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626636, uri, valid, _)

proc call*(call_21626637: Call_DescribeRetentionConfigurations_21626624;
          body: JsonNode): Recallable =
  ## describeRetentionConfigurations
  ## <p>Returns the details of one or more retention configurations. If the retention configuration name is not specified, this action returns the details for all the retention configurations for that account.</p> <note> <p>Currently, AWS Config supports only one retention configuration per region in your account.</p> </note>
  ##   body: JObject (required)
  var body_21626638 = newJObject()
  if body != nil:
    body_21626638 = body
  result = call_21626637.call(nil, nil, nil, nil, body_21626638)

var describeRetentionConfigurations* = Call_DescribeRetentionConfigurations_21626624(
    name: "describeRetentionConfigurations", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeRetentionConfigurations",
    validator: validate_DescribeRetentionConfigurations_21626625, base: "/",
    makeUrl: url_DescribeRetentionConfigurations_21626626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAggregateComplianceDetailsByConfigRule_21626639 = ref object of OpenApiRestCall_21625435
proc url_GetAggregateComplianceDetailsByConfigRule_21626641(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAggregateComplianceDetailsByConfigRule_21626640(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns the evaluation results for the specified AWS Config rule for a specific resource in a rule. The results indicate which AWS resources were evaluated by the rule, when each resource was last evaluated, and whether each resource complies with the rule. </p> <note> <p>The results can return an empty result page. But if you have a <code>nextToken</code>, the results are displayed on the next page.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626642 = header.getOrDefault("X-Amz-Date")
  valid_21626642 = validateParameter(valid_21626642, JString, required = false,
                                   default = nil)
  if valid_21626642 != nil:
    section.add "X-Amz-Date", valid_21626642
  var valid_21626643 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626643 = validateParameter(valid_21626643, JString, required = false,
                                   default = nil)
  if valid_21626643 != nil:
    section.add "X-Amz-Security-Token", valid_21626643
  var valid_21626644 = header.getOrDefault("X-Amz-Target")
  valid_21626644 = validateParameter(valid_21626644, JString, required = true, default = newJString(
      "StarlingDoveService.GetAggregateComplianceDetailsByConfigRule"))
  if valid_21626644 != nil:
    section.add "X-Amz-Target", valid_21626644
  var valid_21626645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626645 = validateParameter(valid_21626645, JString, required = false,
                                   default = nil)
  if valid_21626645 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626645
  var valid_21626646 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-Algorithm", valid_21626646
  var valid_21626647 = header.getOrDefault("X-Amz-Signature")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Signature", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-Credential")
  valid_21626649 = validateParameter(valid_21626649, JString, required = false,
                                   default = nil)
  if valid_21626649 != nil:
    section.add "X-Amz-Credential", valid_21626649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626651: Call_GetAggregateComplianceDetailsByConfigRule_21626639;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the evaluation results for the specified AWS Config rule for a specific resource in a rule. The results indicate which AWS resources were evaluated by the rule, when each resource was last evaluated, and whether each resource complies with the rule. </p> <note> <p>The results can return an empty result page. But if you have a <code>nextToken</code>, the results are displayed on the next page.</p> </note>
  ## 
  let valid = call_21626651.validator(path, query, header, formData, body, _)
  let scheme = call_21626651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626651.makeUrl(scheme.get, call_21626651.host, call_21626651.base,
                               call_21626651.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626651, uri, valid, _)

proc call*(call_21626652: Call_GetAggregateComplianceDetailsByConfigRule_21626639;
          body: JsonNode): Recallable =
  ## getAggregateComplianceDetailsByConfigRule
  ## <p>Returns the evaluation results for the specified AWS Config rule for a specific resource in a rule. The results indicate which AWS resources were evaluated by the rule, when each resource was last evaluated, and whether each resource complies with the rule. </p> <note> <p>The results can return an empty result page. But if you have a <code>nextToken</code>, the results are displayed on the next page.</p> </note>
  ##   body: JObject (required)
  var body_21626653 = newJObject()
  if body != nil:
    body_21626653 = body
  result = call_21626652.call(nil, nil, nil, nil, body_21626653)

var getAggregateComplianceDetailsByConfigRule* = Call_GetAggregateComplianceDetailsByConfigRule_21626639(
    name: "getAggregateComplianceDetailsByConfigRule", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetAggregateComplianceDetailsByConfigRule",
    validator: validate_GetAggregateComplianceDetailsByConfigRule_21626640,
    base: "/", makeUrl: url_GetAggregateComplianceDetailsByConfigRule_21626641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAggregateConfigRuleComplianceSummary_21626654 = ref object of OpenApiRestCall_21625435
proc url_GetAggregateConfigRuleComplianceSummary_21626656(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAggregateConfigRuleComplianceSummary_21626655(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns the number of compliant and noncompliant rules for one or more accounts and regions in an aggregator.</p> <note> <p>The results can return an empty result page, but if you have a nextToken, the results are displayed on the next page.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626657 = header.getOrDefault("X-Amz-Date")
  valid_21626657 = validateParameter(valid_21626657, JString, required = false,
                                   default = nil)
  if valid_21626657 != nil:
    section.add "X-Amz-Date", valid_21626657
  var valid_21626658 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626658 = validateParameter(valid_21626658, JString, required = false,
                                   default = nil)
  if valid_21626658 != nil:
    section.add "X-Amz-Security-Token", valid_21626658
  var valid_21626659 = header.getOrDefault("X-Amz-Target")
  valid_21626659 = validateParameter(valid_21626659, JString, required = true, default = newJString(
      "StarlingDoveService.GetAggregateConfigRuleComplianceSummary"))
  if valid_21626659 != nil:
    section.add "X-Amz-Target", valid_21626659
  var valid_21626660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626660 = validateParameter(valid_21626660, JString, required = false,
                                   default = nil)
  if valid_21626660 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626660
  var valid_21626661 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626661 = validateParameter(valid_21626661, JString, required = false,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "X-Amz-Algorithm", valid_21626661
  var valid_21626662 = header.getOrDefault("X-Amz-Signature")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-Signature", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626663
  var valid_21626664 = header.getOrDefault("X-Amz-Credential")
  valid_21626664 = validateParameter(valid_21626664, JString, required = false,
                                   default = nil)
  if valid_21626664 != nil:
    section.add "X-Amz-Credential", valid_21626664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626666: Call_GetAggregateConfigRuleComplianceSummary_21626654;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the number of compliant and noncompliant rules for one or more accounts and regions in an aggregator.</p> <note> <p>The results can return an empty result page, but if you have a nextToken, the results are displayed on the next page.</p> </note>
  ## 
  let valid = call_21626666.validator(path, query, header, formData, body, _)
  let scheme = call_21626666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626666.makeUrl(scheme.get, call_21626666.host, call_21626666.base,
                               call_21626666.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626666, uri, valid, _)

proc call*(call_21626667: Call_GetAggregateConfigRuleComplianceSummary_21626654;
          body: JsonNode): Recallable =
  ## getAggregateConfigRuleComplianceSummary
  ## <p>Returns the number of compliant and noncompliant rules for one or more accounts and regions in an aggregator.</p> <note> <p>The results can return an empty result page, but if you have a nextToken, the results are displayed on the next page.</p> </note>
  ##   body: JObject (required)
  var body_21626668 = newJObject()
  if body != nil:
    body_21626668 = body
  result = call_21626667.call(nil, nil, nil, nil, body_21626668)

var getAggregateConfigRuleComplianceSummary* = Call_GetAggregateConfigRuleComplianceSummary_21626654(
    name: "getAggregateConfigRuleComplianceSummary", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetAggregateConfigRuleComplianceSummary",
    validator: validate_GetAggregateConfigRuleComplianceSummary_21626655,
    base: "/", makeUrl: url_GetAggregateConfigRuleComplianceSummary_21626656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAggregateDiscoveredResourceCounts_21626669 = ref object of OpenApiRestCall_21625435
proc url_GetAggregateDiscoveredResourceCounts_21626671(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAggregateDiscoveredResourceCounts_21626670(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns the resource counts across accounts and regions that are present in your AWS Config aggregator. You can request the resource counts by providing filters and GroupByKey.</p> <p>For example, if the input contains accountID 12345678910 and region us-east-1 in filters, the API returns the count of resources in account ID 12345678910 and region us-east-1. If the input contains ACCOUNT_ID as a GroupByKey, the API returns resource counts for all source accounts that are present in your aggregator.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626672 = header.getOrDefault("X-Amz-Date")
  valid_21626672 = validateParameter(valid_21626672, JString, required = false,
                                   default = nil)
  if valid_21626672 != nil:
    section.add "X-Amz-Date", valid_21626672
  var valid_21626673 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626673 = validateParameter(valid_21626673, JString, required = false,
                                   default = nil)
  if valid_21626673 != nil:
    section.add "X-Amz-Security-Token", valid_21626673
  var valid_21626674 = header.getOrDefault("X-Amz-Target")
  valid_21626674 = validateParameter(valid_21626674, JString, required = true, default = newJString(
      "StarlingDoveService.GetAggregateDiscoveredResourceCounts"))
  if valid_21626674 != nil:
    section.add "X-Amz-Target", valid_21626674
  var valid_21626675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626675 = validateParameter(valid_21626675, JString, required = false,
                                   default = nil)
  if valid_21626675 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626675
  var valid_21626676 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626676 = validateParameter(valid_21626676, JString, required = false,
                                   default = nil)
  if valid_21626676 != nil:
    section.add "X-Amz-Algorithm", valid_21626676
  var valid_21626677 = header.getOrDefault("X-Amz-Signature")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "X-Amz-Signature", valid_21626677
  var valid_21626678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626678
  var valid_21626679 = header.getOrDefault("X-Amz-Credential")
  valid_21626679 = validateParameter(valid_21626679, JString, required = false,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "X-Amz-Credential", valid_21626679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626681: Call_GetAggregateDiscoveredResourceCounts_21626669;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the resource counts across accounts and regions that are present in your AWS Config aggregator. You can request the resource counts by providing filters and GroupByKey.</p> <p>For example, if the input contains accountID 12345678910 and region us-east-1 in filters, the API returns the count of resources in account ID 12345678910 and region us-east-1. If the input contains ACCOUNT_ID as a GroupByKey, the API returns resource counts for all source accounts that are present in your aggregator.</p>
  ## 
  let valid = call_21626681.validator(path, query, header, formData, body, _)
  let scheme = call_21626681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626681.makeUrl(scheme.get, call_21626681.host, call_21626681.base,
                               call_21626681.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626681, uri, valid, _)

proc call*(call_21626682: Call_GetAggregateDiscoveredResourceCounts_21626669;
          body: JsonNode): Recallable =
  ## getAggregateDiscoveredResourceCounts
  ## <p>Returns the resource counts across accounts and regions that are present in your AWS Config aggregator. You can request the resource counts by providing filters and GroupByKey.</p> <p>For example, if the input contains accountID 12345678910 and region us-east-1 in filters, the API returns the count of resources in account ID 12345678910 and region us-east-1. If the input contains ACCOUNT_ID as a GroupByKey, the API returns resource counts for all source accounts that are present in your aggregator.</p>
  ##   body: JObject (required)
  var body_21626683 = newJObject()
  if body != nil:
    body_21626683 = body
  result = call_21626682.call(nil, nil, nil, nil, body_21626683)

var getAggregateDiscoveredResourceCounts* = Call_GetAggregateDiscoveredResourceCounts_21626669(
    name: "getAggregateDiscoveredResourceCounts", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetAggregateDiscoveredResourceCounts",
    validator: validate_GetAggregateDiscoveredResourceCounts_21626670, base: "/",
    makeUrl: url_GetAggregateDiscoveredResourceCounts_21626671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAggregateResourceConfig_21626684 = ref object of OpenApiRestCall_21625435
proc url_GetAggregateResourceConfig_21626686(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAggregateResourceConfig_21626685(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns configuration item that is aggregated for your specific resource in a specific source account and region.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626687 = header.getOrDefault("X-Amz-Date")
  valid_21626687 = validateParameter(valid_21626687, JString, required = false,
                                   default = nil)
  if valid_21626687 != nil:
    section.add "X-Amz-Date", valid_21626687
  var valid_21626688 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626688 = validateParameter(valid_21626688, JString, required = false,
                                   default = nil)
  if valid_21626688 != nil:
    section.add "X-Amz-Security-Token", valid_21626688
  var valid_21626689 = header.getOrDefault("X-Amz-Target")
  valid_21626689 = validateParameter(valid_21626689, JString, required = true, default = newJString(
      "StarlingDoveService.GetAggregateResourceConfig"))
  if valid_21626689 != nil:
    section.add "X-Amz-Target", valid_21626689
  var valid_21626690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626690 = validateParameter(valid_21626690, JString, required = false,
                                   default = nil)
  if valid_21626690 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626690
  var valid_21626691 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626691 = validateParameter(valid_21626691, JString, required = false,
                                   default = nil)
  if valid_21626691 != nil:
    section.add "X-Amz-Algorithm", valid_21626691
  var valid_21626692 = header.getOrDefault("X-Amz-Signature")
  valid_21626692 = validateParameter(valid_21626692, JString, required = false,
                                   default = nil)
  if valid_21626692 != nil:
    section.add "X-Amz-Signature", valid_21626692
  var valid_21626693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626693 = validateParameter(valid_21626693, JString, required = false,
                                   default = nil)
  if valid_21626693 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626693
  var valid_21626694 = header.getOrDefault("X-Amz-Credential")
  valid_21626694 = validateParameter(valid_21626694, JString, required = false,
                                   default = nil)
  if valid_21626694 != nil:
    section.add "X-Amz-Credential", valid_21626694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626696: Call_GetAggregateResourceConfig_21626684;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns configuration item that is aggregated for your specific resource in a specific source account and region.
  ## 
  let valid = call_21626696.validator(path, query, header, formData, body, _)
  let scheme = call_21626696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626696.makeUrl(scheme.get, call_21626696.host, call_21626696.base,
                               call_21626696.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626696, uri, valid, _)

proc call*(call_21626697: Call_GetAggregateResourceConfig_21626684; body: JsonNode): Recallable =
  ## getAggregateResourceConfig
  ## Returns configuration item that is aggregated for your specific resource in a specific source account and region.
  ##   body: JObject (required)
  var body_21626698 = newJObject()
  if body != nil:
    body_21626698 = body
  result = call_21626697.call(nil, nil, nil, nil, body_21626698)

var getAggregateResourceConfig* = Call_GetAggregateResourceConfig_21626684(
    name: "getAggregateResourceConfig", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.GetAggregateResourceConfig",
    validator: validate_GetAggregateResourceConfig_21626685, base: "/",
    makeUrl: url_GetAggregateResourceConfig_21626686,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComplianceDetailsByConfigRule_21626699 = ref object of OpenApiRestCall_21625435
proc url_GetComplianceDetailsByConfigRule_21626701(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComplianceDetailsByConfigRule_21626700(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns the evaluation results for the specified AWS Config rule. The results indicate which AWS resources were evaluated by the rule, when each resource was last evaluated, and whether each resource complies with the rule.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626702 = header.getOrDefault("X-Amz-Date")
  valid_21626702 = validateParameter(valid_21626702, JString, required = false,
                                   default = nil)
  if valid_21626702 != nil:
    section.add "X-Amz-Date", valid_21626702
  var valid_21626703 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626703 = validateParameter(valid_21626703, JString, required = false,
                                   default = nil)
  if valid_21626703 != nil:
    section.add "X-Amz-Security-Token", valid_21626703
  var valid_21626704 = header.getOrDefault("X-Amz-Target")
  valid_21626704 = validateParameter(valid_21626704, JString, required = true, default = newJString(
      "StarlingDoveService.GetComplianceDetailsByConfigRule"))
  if valid_21626704 != nil:
    section.add "X-Amz-Target", valid_21626704
  var valid_21626705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626705 = validateParameter(valid_21626705, JString, required = false,
                                   default = nil)
  if valid_21626705 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626705
  var valid_21626706 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626706 = validateParameter(valid_21626706, JString, required = false,
                                   default = nil)
  if valid_21626706 != nil:
    section.add "X-Amz-Algorithm", valid_21626706
  var valid_21626707 = header.getOrDefault("X-Amz-Signature")
  valid_21626707 = validateParameter(valid_21626707, JString, required = false,
                                   default = nil)
  if valid_21626707 != nil:
    section.add "X-Amz-Signature", valid_21626707
  var valid_21626708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626708 = validateParameter(valid_21626708, JString, required = false,
                                   default = nil)
  if valid_21626708 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626708
  var valid_21626709 = header.getOrDefault("X-Amz-Credential")
  valid_21626709 = validateParameter(valid_21626709, JString, required = false,
                                   default = nil)
  if valid_21626709 != nil:
    section.add "X-Amz-Credential", valid_21626709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626711: Call_GetComplianceDetailsByConfigRule_21626699;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the evaluation results for the specified AWS Config rule. The results indicate which AWS resources were evaluated by the rule, when each resource was last evaluated, and whether each resource complies with the rule.
  ## 
  let valid = call_21626711.validator(path, query, header, formData, body, _)
  let scheme = call_21626711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626711.makeUrl(scheme.get, call_21626711.host, call_21626711.base,
                               call_21626711.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626711, uri, valid, _)

proc call*(call_21626712: Call_GetComplianceDetailsByConfigRule_21626699;
          body: JsonNode): Recallable =
  ## getComplianceDetailsByConfigRule
  ## Returns the evaluation results for the specified AWS Config rule. The results indicate which AWS resources were evaluated by the rule, when each resource was last evaluated, and whether each resource complies with the rule.
  ##   body: JObject (required)
  var body_21626713 = newJObject()
  if body != nil:
    body_21626713 = body
  result = call_21626712.call(nil, nil, nil, nil, body_21626713)

var getComplianceDetailsByConfigRule* = Call_GetComplianceDetailsByConfigRule_21626699(
    name: "getComplianceDetailsByConfigRule", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetComplianceDetailsByConfigRule",
    validator: validate_GetComplianceDetailsByConfigRule_21626700, base: "/",
    makeUrl: url_GetComplianceDetailsByConfigRule_21626701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComplianceDetailsByResource_21626714 = ref object of OpenApiRestCall_21625435
proc url_GetComplianceDetailsByResource_21626716(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComplianceDetailsByResource_21626715(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns the evaluation results for the specified AWS resource. The results indicate which AWS Config rules were used to evaluate the resource, when each rule was last used, and whether the resource complies with each rule.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626717 = header.getOrDefault("X-Amz-Date")
  valid_21626717 = validateParameter(valid_21626717, JString, required = false,
                                   default = nil)
  if valid_21626717 != nil:
    section.add "X-Amz-Date", valid_21626717
  var valid_21626718 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626718 = validateParameter(valid_21626718, JString, required = false,
                                   default = nil)
  if valid_21626718 != nil:
    section.add "X-Amz-Security-Token", valid_21626718
  var valid_21626719 = header.getOrDefault("X-Amz-Target")
  valid_21626719 = validateParameter(valid_21626719, JString, required = true, default = newJString(
      "StarlingDoveService.GetComplianceDetailsByResource"))
  if valid_21626719 != nil:
    section.add "X-Amz-Target", valid_21626719
  var valid_21626720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626720 = validateParameter(valid_21626720, JString, required = false,
                                   default = nil)
  if valid_21626720 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626720
  var valid_21626721 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626721 = validateParameter(valid_21626721, JString, required = false,
                                   default = nil)
  if valid_21626721 != nil:
    section.add "X-Amz-Algorithm", valid_21626721
  var valid_21626722 = header.getOrDefault("X-Amz-Signature")
  valid_21626722 = validateParameter(valid_21626722, JString, required = false,
                                   default = nil)
  if valid_21626722 != nil:
    section.add "X-Amz-Signature", valid_21626722
  var valid_21626723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626723 = validateParameter(valid_21626723, JString, required = false,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626723
  var valid_21626724 = header.getOrDefault("X-Amz-Credential")
  valid_21626724 = validateParameter(valid_21626724, JString, required = false,
                                   default = nil)
  if valid_21626724 != nil:
    section.add "X-Amz-Credential", valid_21626724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626726: Call_GetComplianceDetailsByResource_21626714;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the evaluation results for the specified AWS resource. The results indicate which AWS Config rules were used to evaluate the resource, when each rule was last used, and whether the resource complies with each rule.
  ## 
  let valid = call_21626726.validator(path, query, header, formData, body, _)
  let scheme = call_21626726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626726.makeUrl(scheme.get, call_21626726.host, call_21626726.base,
                               call_21626726.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626726, uri, valid, _)

proc call*(call_21626727: Call_GetComplianceDetailsByResource_21626714;
          body: JsonNode): Recallable =
  ## getComplianceDetailsByResource
  ## Returns the evaluation results for the specified AWS resource. The results indicate which AWS Config rules were used to evaluate the resource, when each rule was last used, and whether the resource complies with each rule.
  ##   body: JObject (required)
  var body_21626728 = newJObject()
  if body != nil:
    body_21626728 = body
  result = call_21626727.call(nil, nil, nil, nil, body_21626728)

var getComplianceDetailsByResource* = Call_GetComplianceDetailsByResource_21626714(
    name: "getComplianceDetailsByResource", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.GetComplianceDetailsByResource",
    validator: validate_GetComplianceDetailsByResource_21626715, base: "/",
    makeUrl: url_GetComplianceDetailsByResource_21626716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComplianceSummaryByConfigRule_21626729 = ref object of OpenApiRestCall_21625435
proc url_GetComplianceSummaryByConfigRule_21626731(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComplianceSummaryByConfigRule_21626730(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns the number of AWS Config rules that are compliant and noncompliant, up to a maximum of 25 for each.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626732 = header.getOrDefault("X-Amz-Date")
  valid_21626732 = validateParameter(valid_21626732, JString, required = false,
                                   default = nil)
  if valid_21626732 != nil:
    section.add "X-Amz-Date", valid_21626732
  var valid_21626733 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626733 = validateParameter(valid_21626733, JString, required = false,
                                   default = nil)
  if valid_21626733 != nil:
    section.add "X-Amz-Security-Token", valid_21626733
  var valid_21626734 = header.getOrDefault("X-Amz-Target")
  valid_21626734 = validateParameter(valid_21626734, JString, required = true, default = newJString(
      "StarlingDoveService.GetComplianceSummaryByConfigRule"))
  if valid_21626734 != nil:
    section.add "X-Amz-Target", valid_21626734
  var valid_21626735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626735 = validateParameter(valid_21626735, JString, required = false,
                                   default = nil)
  if valid_21626735 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626735
  var valid_21626736 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626736 = validateParameter(valid_21626736, JString, required = false,
                                   default = nil)
  if valid_21626736 != nil:
    section.add "X-Amz-Algorithm", valid_21626736
  var valid_21626737 = header.getOrDefault("X-Amz-Signature")
  valid_21626737 = validateParameter(valid_21626737, JString, required = false,
                                   default = nil)
  if valid_21626737 != nil:
    section.add "X-Amz-Signature", valid_21626737
  var valid_21626738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626738 = validateParameter(valid_21626738, JString, required = false,
                                   default = nil)
  if valid_21626738 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626738
  var valid_21626739 = header.getOrDefault("X-Amz-Credential")
  valid_21626739 = validateParameter(valid_21626739, JString, required = false,
                                   default = nil)
  if valid_21626739 != nil:
    section.add "X-Amz-Credential", valid_21626739
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626740: Call_GetComplianceSummaryByConfigRule_21626729;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the number of AWS Config rules that are compliant and noncompliant, up to a maximum of 25 for each.
  ## 
  let valid = call_21626740.validator(path, query, header, formData, body, _)
  let scheme = call_21626740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626740.makeUrl(scheme.get, call_21626740.host, call_21626740.base,
                               call_21626740.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626740, uri, valid, _)

proc call*(call_21626741: Call_GetComplianceSummaryByConfigRule_21626729): Recallable =
  ## getComplianceSummaryByConfigRule
  ## Returns the number of AWS Config rules that are compliant and noncompliant, up to a maximum of 25 for each.
  result = call_21626741.call(nil, nil, nil, nil, nil)

var getComplianceSummaryByConfigRule* = Call_GetComplianceSummaryByConfigRule_21626729(
    name: "getComplianceSummaryByConfigRule", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetComplianceSummaryByConfigRule",
    validator: validate_GetComplianceSummaryByConfigRule_21626730, base: "/",
    makeUrl: url_GetComplianceSummaryByConfigRule_21626731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComplianceSummaryByResourceType_21626742 = ref object of OpenApiRestCall_21625435
proc url_GetComplianceSummaryByResourceType_21626744(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComplianceSummaryByResourceType_21626743(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns the number of resources that are compliant and the number that are noncompliant. You can specify one or more resource types to get these numbers for each resource type. The maximum number returned is 100.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626745 = header.getOrDefault("X-Amz-Date")
  valid_21626745 = validateParameter(valid_21626745, JString, required = false,
                                   default = nil)
  if valid_21626745 != nil:
    section.add "X-Amz-Date", valid_21626745
  var valid_21626746 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626746 = validateParameter(valid_21626746, JString, required = false,
                                   default = nil)
  if valid_21626746 != nil:
    section.add "X-Amz-Security-Token", valid_21626746
  var valid_21626747 = header.getOrDefault("X-Amz-Target")
  valid_21626747 = validateParameter(valid_21626747, JString, required = true, default = newJString(
      "StarlingDoveService.GetComplianceSummaryByResourceType"))
  if valid_21626747 != nil:
    section.add "X-Amz-Target", valid_21626747
  var valid_21626748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626748 = validateParameter(valid_21626748, JString, required = false,
                                   default = nil)
  if valid_21626748 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626748
  var valid_21626749 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626749 = validateParameter(valid_21626749, JString, required = false,
                                   default = nil)
  if valid_21626749 != nil:
    section.add "X-Amz-Algorithm", valid_21626749
  var valid_21626750 = header.getOrDefault("X-Amz-Signature")
  valid_21626750 = validateParameter(valid_21626750, JString, required = false,
                                   default = nil)
  if valid_21626750 != nil:
    section.add "X-Amz-Signature", valid_21626750
  var valid_21626751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626751 = validateParameter(valid_21626751, JString, required = false,
                                   default = nil)
  if valid_21626751 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626751
  var valid_21626752 = header.getOrDefault("X-Amz-Credential")
  valid_21626752 = validateParameter(valid_21626752, JString, required = false,
                                   default = nil)
  if valid_21626752 != nil:
    section.add "X-Amz-Credential", valid_21626752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626754: Call_GetComplianceSummaryByResourceType_21626742;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the number of resources that are compliant and the number that are noncompliant. You can specify one or more resource types to get these numbers for each resource type. The maximum number returned is 100.
  ## 
  let valid = call_21626754.validator(path, query, header, formData, body, _)
  let scheme = call_21626754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626754.makeUrl(scheme.get, call_21626754.host, call_21626754.base,
                               call_21626754.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626754, uri, valid, _)

proc call*(call_21626755: Call_GetComplianceSummaryByResourceType_21626742;
          body: JsonNode): Recallable =
  ## getComplianceSummaryByResourceType
  ## Returns the number of resources that are compliant and the number that are noncompliant. You can specify one or more resource types to get these numbers for each resource type. The maximum number returned is 100.
  ##   body: JObject (required)
  var body_21626756 = newJObject()
  if body != nil:
    body_21626756 = body
  result = call_21626755.call(nil, nil, nil, nil, body_21626756)

var getComplianceSummaryByResourceType* = Call_GetComplianceSummaryByResourceType_21626742(
    name: "getComplianceSummaryByResourceType", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetComplianceSummaryByResourceType",
    validator: validate_GetComplianceSummaryByResourceType_21626743, base: "/",
    makeUrl: url_GetComplianceSummaryByResourceType_21626744,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConformancePackComplianceDetails_21626757 = ref object of OpenApiRestCall_21625435
proc url_GetConformancePackComplianceDetails_21626759(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConformancePackComplianceDetails_21626758(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns compliance details of a conformance pack for all AWS resources that are monitered by conformance pack.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626760 = header.getOrDefault("X-Amz-Date")
  valid_21626760 = validateParameter(valid_21626760, JString, required = false,
                                   default = nil)
  if valid_21626760 != nil:
    section.add "X-Amz-Date", valid_21626760
  var valid_21626761 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626761 = validateParameter(valid_21626761, JString, required = false,
                                   default = nil)
  if valid_21626761 != nil:
    section.add "X-Amz-Security-Token", valid_21626761
  var valid_21626762 = header.getOrDefault("X-Amz-Target")
  valid_21626762 = validateParameter(valid_21626762, JString, required = true, default = newJString(
      "StarlingDoveService.GetConformancePackComplianceDetails"))
  if valid_21626762 != nil:
    section.add "X-Amz-Target", valid_21626762
  var valid_21626763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626763 = validateParameter(valid_21626763, JString, required = false,
                                   default = nil)
  if valid_21626763 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626763
  var valid_21626764 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626764 = validateParameter(valid_21626764, JString, required = false,
                                   default = nil)
  if valid_21626764 != nil:
    section.add "X-Amz-Algorithm", valid_21626764
  var valid_21626765 = header.getOrDefault("X-Amz-Signature")
  valid_21626765 = validateParameter(valid_21626765, JString, required = false,
                                   default = nil)
  if valid_21626765 != nil:
    section.add "X-Amz-Signature", valid_21626765
  var valid_21626766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626766 = validateParameter(valid_21626766, JString, required = false,
                                   default = nil)
  if valid_21626766 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626766
  var valid_21626767 = header.getOrDefault("X-Amz-Credential")
  valid_21626767 = validateParameter(valid_21626767, JString, required = false,
                                   default = nil)
  if valid_21626767 != nil:
    section.add "X-Amz-Credential", valid_21626767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626769: Call_GetConformancePackComplianceDetails_21626757;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns compliance details of a conformance pack for all AWS resources that are monitered by conformance pack.
  ## 
  let valid = call_21626769.validator(path, query, header, formData, body, _)
  let scheme = call_21626769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626769.makeUrl(scheme.get, call_21626769.host, call_21626769.base,
                               call_21626769.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626769, uri, valid, _)

proc call*(call_21626770: Call_GetConformancePackComplianceDetails_21626757;
          body: JsonNode): Recallable =
  ## getConformancePackComplianceDetails
  ## Returns compliance details of a conformance pack for all AWS resources that are monitered by conformance pack.
  ##   body: JObject (required)
  var body_21626771 = newJObject()
  if body != nil:
    body_21626771 = body
  result = call_21626770.call(nil, nil, nil, nil, body_21626771)

var getConformancePackComplianceDetails* = Call_GetConformancePackComplianceDetails_21626757(
    name: "getConformancePackComplianceDetails", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetConformancePackComplianceDetails",
    validator: validate_GetConformancePackComplianceDetails_21626758, base: "/",
    makeUrl: url_GetConformancePackComplianceDetails_21626759,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConformancePackComplianceSummary_21626772 = ref object of OpenApiRestCall_21625435
proc url_GetConformancePackComplianceSummary_21626774(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConformancePackComplianceSummary_21626773(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns compliance details for the conformance pack based on the cumulative compliance results of all the rules in that conformance pack.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626775 = header.getOrDefault("X-Amz-Date")
  valid_21626775 = validateParameter(valid_21626775, JString, required = false,
                                   default = nil)
  if valid_21626775 != nil:
    section.add "X-Amz-Date", valid_21626775
  var valid_21626776 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626776 = validateParameter(valid_21626776, JString, required = false,
                                   default = nil)
  if valid_21626776 != nil:
    section.add "X-Amz-Security-Token", valid_21626776
  var valid_21626777 = header.getOrDefault("X-Amz-Target")
  valid_21626777 = validateParameter(valid_21626777, JString, required = true, default = newJString(
      "StarlingDoveService.GetConformancePackComplianceSummary"))
  if valid_21626777 != nil:
    section.add "X-Amz-Target", valid_21626777
  var valid_21626778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626778 = validateParameter(valid_21626778, JString, required = false,
                                   default = nil)
  if valid_21626778 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626778
  var valid_21626779 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626779 = validateParameter(valid_21626779, JString, required = false,
                                   default = nil)
  if valid_21626779 != nil:
    section.add "X-Amz-Algorithm", valid_21626779
  var valid_21626780 = header.getOrDefault("X-Amz-Signature")
  valid_21626780 = validateParameter(valid_21626780, JString, required = false,
                                   default = nil)
  if valid_21626780 != nil:
    section.add "X-Amz-Signature", valid_21626780
  var valid_21626781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626781 = validateParameter(valid_21626781, JString, required = false,
                                   default = nil)
  if valid_21626781 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626781
  var valid_21626782 = header.getOrDefault("X-Amz-Credential")
  valid_21626782 = validateParameter(valid_21626782, JString, required = false,
                                   default = nil)
  if valid_21626782 != nil:
    section.add "X-Amz-Credential", valid_21626782
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626784: Call_GetConformancePackComplianceSummary_21626772;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns compliance details for the conformance pack based on the cumulative compliance results of all the rules in that conformance pack.
  ## 
  let valid = call_21626784.validator(path, query, header, formData, body, _)
  let scheme = call_21626784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626784.makeUrl(scheme.get, call_21626784.host, call_21626784.base,
                               call_21626784.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626784, uri, valid, _)

proc call*(call_21626785: Call_GetConformancePackComplianceSummary_21626772;
          body: JsonNode): Recallable =
  ## getConformancePackComplianceSummary
  ## Returns compliance details for the conformance pack based on the cumulative compliance results of all the rules in that conformance pack.
  ##   body: JObject (required)
  var body_21626786 = newJObject()
  if body != nil:
    body_21626786 = body
  result = call_21626785.call(nil, nil, nil, nil, body_21626786)

var getConformancePackComplianceSummary* = Call_GetConformancePackComplianceSummary_21626772(
    name: "getConformancePackComplianceSummary", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetConformancePackComplianceSummary",
    validator: validate_GetConformancePackComplianceSummary_21626773, base: "/",
    makeUrl: url_GetConformancePackComplianceSummary_21626774,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiscoveredResourceCounts_21626787 = ref object of OpenApiRestCall_21625435
proc url_GetDiscoveredResourceCounts_21626789(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDiscoveredResourceCounts_21626788(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns the resource types, the number of each resource type, and the total number of resources that AWS Config is recording in this region for your AWS account. </p> <p class="title"> <b>Example</b> </p> <ol> <li> <p>AWS Config is recording three resource types in the US East (Ohio) Region for your account: 25 EC2 instances, 20 IAM users, and 15 S3 buckets.</p> </li> <li> <p>You make a call to the <code>GetDiscoveredResourceCounts</code> action and specify that you want all resource types. </p> </li> <li> <p>AWS Config returns the following:</p> <ul> <li> <p>The resource types (EC2 instances, IAM users, and S3 buckets).</p> </li> <li> <p>The number of each resource type (25, 20, and 15).</p> </li> <li> <p>The total number of all resources (60).</p> </li> </ul> </li> </ol> <p>The response is paginated. By default, AWS Config lists 100 <a>ResourceCount</a> objects on each page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p> <note> <p>If you make a call to the <a>GetDiscoveredResourceCounts</a> action, you might not immediately receive resource counts in the following situations:</p> <ul> <li> <p>You are a new AWS Config customer.</p> </li> <li> <p>You just enabled resource recording.</p> </li> </ul> <p>It might take a few minutes for AWS Config to record and count your resources. Wait a few minutes and then retry the <a>GetDiscoveredResourceCounts</a> action. </p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626790 = header.getOrDefault("X-Amz-Date")
  valid_21626790 = validateParameter(valid_21626790, JString, required = false,
                                   default = nil)
  if valid_21626790 != nil:
    section.add "X-Amz-Date", valid_21626790
  var valid_21626791 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626791 = validateParameter(valid_21626791, JString, required = false,
                                   default = nil)
  if valid_21626791 != nil:
    section.add "X-Amz-Security-Token", valid_21626791
  var valid_21626792 = header.getOrDefault("X-Amz-Target")
  valid_21626792 = validateParameter(valid_21626792, JString, required = true, default = newJString(
      "StarlingDoveService.GetDiscoveredResourceCounts"))
  if valid_21626792 != nil:
    section.add "X-Amz-Target", valid_21626792
  var valid_21626793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626793 = validateParameter(valid_21626793, JString, required = false,
                                   default = nil)
  if valid_21626793 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626793
  var valid_21626794 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626794 = validateParameter(valid_21626794, JString, required = false,
                                   default = nil)
  if valid_21626794 != nil:
    section.add "X-Amz-Algorithm", valid_21626794
  var valid_21626795 = header.getOrDefault("X-Amz-Signature")
  valid_21626795 = validateParameter(valid_21626795, JString, required = false,
                                   default = nil)
  if valid_21626795 != nil:
    section.add "X-Amz-Signature", valid_21626795
  var valid_21626796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626796 = validateParameter(valid_21626796, JString, required = false,
                                   default = nil)
  if valid_21626796 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626796
  var valid_21626797 = header.getOrDefault("X-Amz-Credential")
  valid_21626797 = validateParameter(valid_21626797, JString, required = false,
                                   default = nil)
  if valid_21626797 != nil:
    section.add "X-Amz-Credential", valid_21626797
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626799: Call_GetDiscoveredResourceCounts_21626787;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the resource types, the number of each resource type, and the total number of resources that AWS Config is recording in this region for your AWS account. </p> <p class="title"> <b>Example</b> </p> <ol> <li> <p>AWS Config is recording three resource types in the US East (Ohio) Region for your account: 25 EC2 instances, 20 IAM users, and 15 S3 buckets.</p> </li> <li> <p>You make a call to the <code>GetDiscoveredResourceCounts</code> action and specify that you want all resource types. </p> </li> <li> <p>AWS Config returns the following:</p> <ul> <li> <p>The resource types (EC2 instances, IAM users, and S3 buckets).</p> </li> <li> <p>The number of each resource type (25, 20, and 15).</p> </li> <li> <p>The total number of all resources (60).</p> </li> </ul> </li> </ol> <p>The response is paginated. By default, AWS Config lists 100 <a>ResourceCount</a> objects on each page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p> <note> <p>If you make a call to the <a>GetDiscoveredResourceCounts</a> action, you might not immediately receive resource counts in the following situations:</p> <ul> <li> <p>You are a new AWS Config customer.</p> </li> <li> <p>You just enabled resource recording.</p> </li> </ul> <p>It might take a few minutes for AWS Config to record and count your resources. Wait a few minutes and then retry the <a>GetDiscoveredResourceCounts</a> action. </p> </note>
  ## 
  let valid = call_21626799.validator(path, query, header, formData, body, _)
  let scheme = call_21626799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626799.makeUrl(scheme.get, call_21626799.host, call_21626799.base,
                               call_21626799.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626799, uri, valid, _)

proc call*(call_21626800: Call_GetDiscoveredResourceCounts_21626787; body: JsonNode): Recallable =
  ## getDiscoveredResourceCounts
  ## <p>Returns the resource types, the number of each resource type, and the total number of resources that AWS Config is recording in this region for your AWS account. </p> <p class="title"> <b>Example</b> </p> <ol> <li> <p>AWS Config is recording three resource types in the US East (Ohio) Region for your account: 25 EC2 instances, 20 IAM users, and 15 S3 buckets.</p> </li> <li> <p>You make a call to the <code>GetDiscoveredResourceCounts</code> action and specify that you want all resource types. </p> </li> <li> <p>AWS Config returns the following:</p> <ul> <li> <p>The resource types (EC2 instances, IAM users, and S3 buckets).</p> </li> <li> <p>The number of each resource type (25, 20, and 15).</p> </li> <li> <p>The total number of all resources (60).</p> </li> </ul> </li> </ol> <p>The response is paginated. By default, AWS Config lists 100 <a>ResourceCount</a> objects on each page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p> <note> <p>If you make a call to the <a>GetDiscoveredResourceCounts</a> action, you might not immediately receive resource counts in the following situations:</p> <ul> <li> <p>You are a new AWS Config customer.</p> </li> <li> <p>You just enabled resource recording.</p> </li> </ul> <p>It might take a few minutes for AWS Config to record and count your resources. Wait a few minutes and then retry the <a>GetDiscoveredResourceCounts</a> action. </p> </note>
  ##   body: JObject (required)
  var body_21626801 = newJObject()
  if body != nil:
    body_21626801 = body
  result = call_21626800.call(nil, nil, nil, nil, body_21626801)

var getDiscoveredResourceCounts* = Call_GetDiscoveredResourceCounts_21626787(
    name: "getDiscoveredResourceCounts", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.GetDiscoveredResourceCounts",
    validator: validate_GetDiscoveredResourceCounts_21626788, base: "/",
    makeUrl: url_GetDiscoveredResourceCounts_21626789,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOrganizationConfigRuleDetailedStatus_21626802 = ref object of OpenApiRestCall_21625435
proc url_GetOrganizationConfigRuleDetailedStatus_21626804(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOrganizationConfigRuleDetailedStatus_21626803(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns detailed status for each member account within an organization for a given organization config rule.</p> <note> <p>Only a master account can call this API.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626805 = header.getOrDefault("X-Amz-Date")
  valid_21626805 = validateParameter(valid_21626805, JString, required = false,
                                   default = nil)
  if valid_21626805 != nil:
    section.add "X-Amz-Date", valid_21626805
  var valid_21626806 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626806 = validateParameter(valid_21626806, JString, required = false,
                                   default = nil)
  if valid_21626806 != nil:
    section.add "X-Amz-Security-Token", valid_21626806
  var valid_21626807 = header.getOrDefault("X-Amz-Target")
  valid_21626807 = validateParameter(valid_21626807, JString, required = true, default = newJString(
      "StarlingDoveService.GetOrganizationConfigRuleDetailedStatus"))
  if valid_21626807 != nil:
    section.add "X-Amz-Target", valid_21626807
  var valid_21626808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626808 = validateParameter(valid_21626808, JString, required = false,
                                   default = nil)
  if valid_21626808 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626808
  var valid_21626809 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626809 = validateParameter(valid_21626809, JString, required = false,
                                   default = nil)
  if valid_21626809 != nil:
    section.add "X-Amz-Algorithm", valid_21626809
  var valid_21626810 = header.getOrDefault("X-Amz-Signature")
  valid_21626810 = validateParameter(valid_21626810, JString, required = false,
                                   default = nil)
  if valid_21626810 != nil:
    section.add "X-Amz-Signature", valid_21626810
  var valid_21626811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626811 = validateParameter(valid_21626811, JString, required = false,
                                   default = nil)
  if valid_21626811 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626811
  var valid_21626812 = header.getOrDefault("X-Amz-Credential")
  valid_21626812 = validateParameter(valid_21626812, JString, required = false,
                                   default = nil)
  if valid_21626812 != nil:
    section.add "X-Amz-Credential", valid_21626812
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626814: Call_GetOrganizationConfigRuleDetailedStatus_21626802;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns detailed status for each member account within an organization for a given organization config rule.</p> <note> <p>Only a master account can call this API.</p> </note>
  ## 
  let valid = call_21626814.validator(path, query, header, formData, body, _)
  let scheme = call_21626814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626814.makeUrl(scheme.get, call_21626814.host, call_21626814.base,
                               call_21626814.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626814, uri, valid, _)

proc call*(call_21626815: Call_GetOrganizationConfigRuleDetailedStatus_21626802;
          body: JsonNode): Recallable =
  ## getOrganizationConfigRuleDetailedStatus
  ## <p>Returns detailed status for each member account within an organization for a given organization config rule.</p> <note> <p>Only a master account can call this API.</p> </note>
  ##   body: JObject (required)
  var body_21626816 = newJObject()
  if body != nil:
    body_21626816 = body
  result = call_21626815.call(nil, nil, nil, nil, body_21626816)

var getOrganizationConfigRuleDetailedStatus* = Call_GetOrganizationConfigRuleDetailedStatus_21626802(
    name: "getOrganizationConfigRuleDetailedStatus", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetOrganizationConfigRuleDetailedStatus",
    validator: validate_GetOrganizationConfigRuleDetailedStatus_21626803,
    base: "/", makeUrl: url_GetOrganizationConfigRuleDetailedStatus_21626804,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOrganizationConformancePackDetailedStatus_21626817 = ref object of OpenApiRestCall_21625435
proc url_GetOrganizationConformancePackDetailedStatus_21626819(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOrganizationConformancePackDetailedStatus_21626818(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns detailed status for each member account within an organization for a given organization conformance pack.</p> <p>Only a master account can call this API.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626820 = header.getOrDefault("X-Amz-Date")
  valid_21626820 = validateParameter(valid_21626820, JString, required = false,
                                   default = nil)
  if valid_21626820 != nil:
    section.add "X-Amz-Date", valid_21626820
  var valid_21626821 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626821 = validateParameter(valid_21626821, JString, required = false,
                                   default = nil)
  if valid_21626821 != nil:
    section.add "X-Amz-Security-Token", valid_21626821
  var valid_21626822 = header.getOrDefault("X-Amz-Target")
  valid_21626822 = validateParameter(valid_21626822, JString, required = true, default = newJString(
      "StarlingDoveService.GetOrganizationConformancePackDetailedStatus"))
  if valid_21626822 != nil:
    section.add "X-Amz-Target", valid_21626822
  var valid_21626823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626823 = validateParameter(valid_21626823, JString, required = false,
                                   default = nil)
  if valid_21626823 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626823
  var valid_21626824 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626824 = validateParameter(valid_21626824, JString, required = false,
                                   default = nil)
  if valid_21626824 != nil:
    section.add "X-Amz-Algorithm", valid_21626824
  var valid_21626825 = header.getOrDefault("X-Amz-Signature")
  valid_21626825 = validateParameter(valid_21626825, JString, required = false,
                                   default = nil)
  if valid_21626825 != nil:
    section.add "X-Amz-Signature", valid_21626825
  var valid_21626826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626826 = validateParameter(valid_21626826, JString, required = false,
                                   default = nil)
  if valid_21626826 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626826
  var valid_21626827 = header.getOrDefault("X-Amz-Credential")
  valid_21626827 = validateParameter(valid_21626827, JString, required = false,
                                   default = nil)
  if valid_21626827 != nil:
    section.add "X-Amz-Credential", valid_21626827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626829: Call_GetOrganizationConformancePackDetailedStatus_21626817;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns detailed status for each member account within an organization for a given organization conformance pack.</p> <p>Only a master account can call this API.</p>
  ## 
  let valid = call_21626829.validator(path, query, header, formData, body, _)
  let scheme = call_21626829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626829.makeUrl(scheme.get, call_21626829.host, call_21626829.base,
                               call_21626829.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626829, uri, valid, _)

proc call*(call_21626830: Call_GetOrganizationConformancePackDetailedStatus_21626817;
          body: JsonNode): Recallable =
  ## getOrganizationConformancePackDetailedStatus
  ## <p>Returns detailed status for each member account within an organization for a given organization conformance pack.</p> <p>Only a master account can call this API.</p>
  ##   body: JObject (required)
  var body_21626831 = newJObject()
  if body != nil:
    body_21626831 = body
  result = call_21626830.call(nil, nil, nil, nil, body_21626831)

var getOrganizationConformancePackDetailedStatus* = Call_GetOrganizationConformancePackDetailedStatus_21626817(
    name: "getOrganizationConformancePackDetailedStatus",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetOrganizationConformancePackDetailedStatus",
    validator: validate_GetOrganizationConformancePackDetailedStatus_21626818,
    base: "/", makeUrl: url_GetOrganizationConformancePackDetailedStatus_21626819,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceConfigHistory_21626832 = ref object of OpenApiRestCall_21625435
proc url_GetResourceConfigHistory_21626834(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResourceConfigHistory_21626833(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a list of configuration items for the specified resource. The list contains details about each state of the resource during the specified time interval. If you specified a retention period to retain your <code>ConfigurationItems</code> between a minimum of 30 days and a maximum of 7 years (2557 days), AWS Config returns the <code>ConfigurationItems</code> for the specified retention period. </p> <p>The response is paginated. By default, AWS Config returns a limit of 10 configuration items per page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p> <note> <p>Each call to the API is limited to span a duration of seven days. It is likely that the number of records returned is smaller than the specified <code>limit</code>. In such cases, you can make another call, using the <code>nextToken</code>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_21626835 = query.getOrDefault("nextToken")
  valid_21626835 = validateParameter(valid_21626835, JString, required = false,
                                   default = nil)
  if valid_21626835 != nil:
    section.add "nextToken", valid_21626835
  var valid_21626836 = query.getOrDefault("limit")
  valid_21626836 = validateParameter(valid_21626836, JString, required = false,
                                   default = nil)
  if valid_21626836 != nil:
    section.add "limit", valid_21626836
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626837 = header.getOrDefault("X-Amz-Date")
  valid_21626837 = validateParameter(valid_21626837, JString, required = false,
                                   default = nil)
  if valid_21626837 != nil:
    section.add "X-Amz-Date", valid_21626837
  var valid_21626838 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626838 = validateParameter(valid_21626838, JString, required = false,
                                   default = nil)
  if valid_21626838 != nil:
    section.add "X-Amz-Security-Token", valid_21626838
  var valid_21626839 = header.getOrDefault("X-Amz-Target")
  valid_21626839 = validateParameter(valid_21626839, JString, required = true, default = newJString(
      "StarlingDoveService.GetResourceConfigHistory"))
  if valid_21626839 != nil:
    section.add "X-Amz-Target", valid_21626839
  var valid_21626840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626840 = validateParameter(valid_21626840, JString, required = false,
                                   default = nil)
  if valid_21626840 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626840
  var valid_21626841 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626841 = validateParameter(valid_21626841, JString, required = false,
                                   default = nil)
  if valid_21626841 != nil:
    section.add "X-Amz-Algorithm", valid_21626841
  var valid_21626842 = header.getOrDefault("X-Amz-Signature")
  valid_21626842 = validateParameter(valid_21626842, JString, required = false,
                                   default = nil)
  if valid_21626842 != nil:
    section.add "X-Amz-Signature", valid_21626842
  var valid_21626843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626843 = validateParameter(valid_21626843, JString, required = false,
                                   default = nil)
  if valid_21626843 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626843
  var valid_21626844 = header.getOrDefault("X-Amz-Credential")
  valid_21626844 = validateParameter(valid_21626844, JString, required = false,
                                   default = nil)
  if valid_21626844 != nil:
    section.add "X-Amz-Credential", valid_21626844
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626846: Call_GetResourceConfigHistory_21626832;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of configuration items for the specified resource. The list contains details about each state of the resource during the specified time interval. If you specified a retention period to retain your <code>ConfigurationItems</code> between a minimum of 30 days and a maximum of 7 years (2557 days), AWS Config returns the <code>ConfigurationItems</code> for the specified retention period. </p> <p>The response is paginated. By default, AWS Config returns a limit of 10 configuration items per page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p> <note> <p>Each call to the API is limited to span a duration of seven days. It is likely that the number of records returned is smaller than the specified <code>limit</code>. In such cases, you can make another call, using the <code>nextToken</code>.</p> </note>
  ## 
  let valid = call_21626846.validator(path, query, header, formData, body, _)
  let scheme = call_21626846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626846.makeUrl(scheme.get, call_21626846.host, call_21626846.base,
                               call_21626846.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626846, uri, valid, _)

proc call*(call_21626847: Call_GetResourceConfigHistory_21626832; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## getResourceConfigHistory
  ## <p>Returns a list of configuration items for the specified resource. The list contains details about each state of the resource during the specified time interval. If you specified a retention period to retain your <code>ConfigurationItems</code> between a minimum of 30 days and a maximum of 7 years (2557 days), AWS Config returns the <code>ConfigurationItems</code> for the specified retention period. </p> <p>The response is paginated. By default, AWS Config returns a limit of 10 configuration items per page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p> <note> <p>Each call to the API is limited to span a duration of seven days. It is likely that the number of records returned is smaller than the specified <code>limit</code>. In such cases, you can make another call, using the <code>nextToken</code>.</p> </note>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   limit: string
  ##        : Pagination limit
  var query_21626848 = newJObject()
  var body_21626849 = newJObject()
  add(query_21626848, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626849 = body
  add(query_21626848, "limit", newJString(limit))
  result = call_21626847.call(nil, query_21626848, nil, nil, body_21626849)

var getResourceConfigHistory* = Call_GetResourceConfigHistory_21626832(
    name: "getResourceConfigHistory", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.GetResourceConfigHistory",
    validator: validate_GetResourceConfigHistory_21626833, base: "/",
    makeUrl: url_GetResourceConfigHistory_21626834,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAggregateDiscoveredResources_21626850 = ref object of OpenApiRestCall_21625435
proc url_ListAggregateDiscoveredResources_21626852(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAggregateDiscoveredResources_21626851(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Accepts a resource type and returns a list of resource identifiers that are aggregated for a specific resource type across accounts and regions. A resource identifier includes the resource type, ID, (if available) the custom resource name, source account, and source region. You can narrow the results to include only resources that have specific resource IDs, or a resource name, or source account ID, or source region.</p> <p>For example, if the input consists of accountID 12345678910 and the region is us-east-1 for resource type <code>AWS::EC2::Instance</code> then the API returns all the EC2 instance identifiers of accountID 12345678910 and region us-east-1.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626853 = header.getOrDefault("X-Amz-Date")
  valid_21626853 = validateParameter(valid_21626853, JString, required = false,
                                   default = nil)
  if valid_21626853 != nil:
    section.add "X-Amz-Date", valid_21626853
  var valid_21626854 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626854 = validateParameter(valid_21626854, JString, required = false,
                                   default = nil)
  if valid_21626854 != nil:
    section.add "X-Amz-Security-Token", valid_21626854
  var valid_21626855 = header.getOrDefault("X-Amz-Target")
  valid_21626855 = validateParameter(valid_21626855, JString, required = true, default = newJString(
      "StarlingDoveService.ListAggregateDiscoveredResources"))
  if valid_21626855 != nil:
    section.add "X-Amz-Target", valid_21626855
  var valid_21626856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626856 = validateParameter(valid_21626856, JString, required = false,
                                   default = nil)
  if valid_21626856 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626856
  var valid_21626857 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626857 = validateParameter(valid_21626857, JString, required = false,
                                   default = nil)
  if valid_21626857 != nil:
    section.add "X-Amz-Algorithm", valid_21626857
  var valid_21626858 = header.getOrDefault("X-Amz-Signature")
  valid_21626858 = validateParameter(valid_21626858, JString, required = false,
                                   default = nil)
  if valid_21626858 != nil:
    section.add "X-Amz-Signature", valid_21626858
  var valid_21626859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626859 = validateParameter(valid_21626859, JString, required = false,
                                   default = nil)
  if valid_21626859 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626859
  var valid_21626860 = header.getOrDefault("X-Amz-Credential")
  valid_21626860 = validateParameter(valid_21626860, JString, required = false,
                                   default = nil)
  if valid_21626860 != nil:
    section.add "X-Amz-Credential", valid_21626860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626862: Call_ListAggregateDiscoveredResources_21626850;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Accepts a resource type and returns a list of resource identifiers that are aggregated for a specific resource type across accounts and regions. A resource identifier includes the resource type, ID, (if available) the custom resource name, source account, and source region. You can narrow the results to include only resources that have specific resource IDs, or a resource name, or source account ID, or source region.</p> <p>For example, if the input consists of accountID 12345678910 and the region is us-east-1 for resource type <code>AWS::EC2::Instance</code> then the API returns all the EC2 instance identifiers of accountID 12345678910 and region us-east-1.</p>
  ## 
  let valid = call_21626862.validator(path, query, header, formData, body, _)
  let scheme = call_21626862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626862.makeUrl(scheme.get, call_21626862.host, call_21626862.base,
                               call_21626862.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626862, uri, valid, _)

proc call*(call_21626863: Call_ListAggregateDiscoveredResources_21626850;
          body: JsonNode): Recallable =
  ## listAggregateDiscoveredResources
  ## <p>Accepts a resource type and returns a list of resource identifiers that are aggregated for a specific resource type across accounts and regions. A resource identifier includes the resource type, ID, (if available) the custom resource name, source account, and source region. You can narrow the results to include only resources that have specific resource IDs, or a resource name, or source account ID, or source region.</p> <p>For example, if the input consists of accountID 12345678910 and the region is us-east-1 for resource type <code>AWS::EC2::Instance</code> then the API returns all the EC2 instance identifiers of accountID 12345678910 and region us-east-1.</p>
  ##   body: JObject (required)
  var body_21626864 = newJObject()
  if body != nil:
    body_21626864 = body
  result = call_21626863.call(nil, nil, nil, nil, body_21626864)

var listAggregateDiscoveredResources* = Call_ListAggregateDiscoveredResources_21626850(
    name: "listAggregateDiscoveredResources", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.ListAggregateDiscoveredResources",
    validator: validate_ListAggregateDiscoveredResources_21626851, base: "/",
    makeUrl: url_ListAggregateDiscoveredResources_21626852,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDiscoveredResources_21626865 = ref object of OpenApiRestCall_21625435
proc url_ListDiscoveredResources_21626867(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDiscoveredResources_21626866(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Accepts a resource type and returns a list of resource identifiers for the resources of that type. A resource identifier includes the resource type, ID, and (if available) the custom resource name. The results consist of resources that AWS Config has discovered, including those that AWS Config is not currently recording. You can narrow the results to include only resources that have specific resource IDs or a resource name.</p> <note> <p>You can specify either resource IDs or a resource name, but not both, in the same request.</p> </note> <p>The response is paginated. By default, AWS Config lists 100 resource identifiers on each page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626868 = header.getOrDefault("X-Amz-Date")
  valid_21626868 = validateParameter(valid_21626868, JString, required = false,
                                   default = nil)
  if valid_21626868 != nil:
    section.add "X-Amz-Date", valid_21626868
  var valid_21626869 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626869 = validateParameter(valid_21626869, JString, required = false,
                                   default = nil)
  if valid_21626869 != nil:
    section.add "X-Amz-Security-Token", valid_21626869
  var valid_21626870 = header.getOrDefault("X-Amz-Target")
  valid_21626870 = validateParameter(valid_21626870, JString, required = true, default = newJString(
      "StarlingDoveService.ListDiscoveredResources"))
  if valid_21626870 != nil:
    section.add "X-Amz-Target", valid_21626870
  var valid_21626871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626871 = validateParameter(valid_21626871, JString, required = false,
                                   default = nil)
  if valid_21626871 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626871
  var valid_21626872 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626872 = validateParameter(valid_21626872, JString, required = false,
                                   default = nil)
  if valid_21626872 != nil:
    section.add "X-Amz-Algorithm", valid_21626872
  var valid_21626873 = header.getOrDefault("X-Amz-Signature")
  valid_21626873 = validateParameter(valid_21626873, JString, required = false,
                                   default = nil)
  if valid_21626873 != nil:
    section.add "X-Amz-Signature", valid_21626873
  var valid_21626874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626874 = validateParameter(valid_21626874, JString, required = false,
                                   default = nil)
  if valid_21626874 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626874
  var valid_21626875 = header.getOrDefault("X-Amz-Credential")
  valid_21626875 = validateParameter(valid_21626875, JString, required = false,
                                   default = nil)
  if valid_21626875 != nil:
    section.add "X-Amz-Credential", valid_21626875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626877: Call_ListDiscoveredResources_21626865;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Accepts a resource type and returns a list of resource identifiers for the resources of that type. A resource identifier includes the resource type, ID, and (if available) the custom resource name. The results consist of resources that AWS Config has discovered, including those that AWS Config is not currently recording. You can narrow the results to include only resources that have specific resource IDs or a resource name.</p> <note> <p>You can specify either resource IDs or a resource name, but not both, in the same request.</p> </note> <p>The response is paginated. By default, AWS Config lists 100 resource identifiers on each page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p>
  ## 
  let valid = call_21626877.validator(path, query, header, formData, body, _)
  let scheme = call_21626877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626877.makeUrl(scheme.get, call_21626877.host, call_21626877.base,
                               call_21626877.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626877, uri, valid, _)

proc call*(call_21626878: Call_ListDiscoveredResources_21626865; body: JsonNode): Recallable =
  ## listDiscoveredResources
  ## <p>Accepts a resource type and returns a list of resource identifiers for the resources of that type. A resource identifier includes the resource type, ID, and (if available) the custom resource name. The results consist of resources that AWS Config has discovered, including those that AWS Config is not currently recording. You can narrow the results to include only resources that have specific resource IDs or a resource name.</p> <note> <p>You can specify either resource IDs or a resource name, but not both, in the same request.</p> </note> <p>The response is paginated. By default, AWS Config lists 100 resource identifiers on each page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p>
  ##   body: JObject (required)
  var body_21626879 = newJObject()
  if body != nil:
    body_21626879 = body
  result = call_21626878.call(nil, nil, nil, nil, body_21626879)

var listDiscoveredResources* = Call_ListDiscoveredResources_21626865(
    name: "listDiscoveredResources", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.ListDiscoveredResources",
    validator: validate_ListDiscoveredResources_21626866, base: "/",
    makeUrl: url_ListDiscoveredResources_21626867,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626880 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626882(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_21626881(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List the tags for AWS Config resource.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626883 = header.getOrDefault("X-Amz-Date")
  valid_21626883 = validateParameter(valid_21626883, JString, required = false,
                                   default = nil)
  if valid_21626883 != nil:
    section.add "X-Amz-Date", valid_21626883
  var valid_21626884 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626884 = validateParameter(valid_21626884, JString, required = false,
                                   default = nil)
  if valid_21626884 != nil:
    section.add "X-Amz-Security-Token", valid_21626884
  var valid_21626885 = header.getOrDefault("X-Amz-Target")
  valid_21626885 = validateParameter(valid_21626885, JString, required = true, default = newJString(
      "StarlingDoveService.ListTagsForResource"))
  if valid_21626885 != nil:
    section.add "X-Amz-Target", valid_21626885
  var valid_21626886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626886 = validateParameter(valid_21626886, JString, required = false,
                                   default = nil)
  if valid_21626886 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626886
  var valid_21626887 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626887 = validateParameter(valid_21626887, JString, required = false,
                                   default = nil)
  if valid_21626887 != nil:
    section.add "X-Amz-Algorithm", valid_21626887
  var valid_21626888 = header.getOrDefault("X-Amz-Signature")
  valid_21626888 = validateParameter(valid_21626888, JString, required = false,
                                   default = nil)
  if valid_21626888 != nil:
    section.add "X-Amz-Signature", valid_21626888
  var valid_21626889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626889 = validateParameter(valid_21626889, JString, required = false,
                                   default = nil)
  if valid_21626889 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626889
  var valid_21626890 = header.getOrDefault("X-Amz-Credential")
  valid_21626890 = validateParameter(valid_21626890, JString, required = false,
                                   default = nil)
  if valid_21626890 != nil:
    section.add "X-Amz-Credential", valid_21626890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626892: Call_ListTagsForResource_21626880; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List the tags for AWS Config resource.
  ## 
  let valid = call_21626892.validator(path, query, header, formData, body, _)
  let scheme = call_21626892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626892.makeUrl(scheme.get, call_21626892.host, call_21626892.base,
                               call_21626892.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626892, uri, valid, _)

proc call*(call_21626893: Call_ListTagsForResource_21626880; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for AWS Config resource.
  ##   body: JObject (required)
  var body_21626894 = newJObject()
  if body != nil:
    body_21626894 = body
  result = call_21626893.call(nil, nil, nil, nil, body_21626894)

var listTagsForResource* = Call_ListTagsForResource_21626880(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.ListTagsForResource",
    validator: validate_ListTagsForResource_21626881, base: "/",
    makeUrl: url_ListTagsForResource_21626882,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAggregationAuthorization_21626895 = ref object of OpenApiRestCall_21625435
proc url_PutAggregationAuthorization_21626897(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutAggregationAuthorization_21626896(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Authorizes the aggregator account and region to collect data from the source account and region. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626898 = header.getOrDefault("X-Amz-Date")
  valid_21626898 = validateParameter(valid_21626898, JString, required = false,
                                   default = nil)
  if valid_21626898 != nil:
    section.add "X-Amz-Date", valid_21626898
  var valid_21626899 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626899 = validateParameter(valid_21626899, JString, required = false,
                                   default = nil)
  if valid_21626899 != nil:
    section.add "X-Amz-Security-Token", valid_21626899
  var valid_21626900 = header.getOrDefault("X-Amz-Target")
  valid_21626900 = validateParameter(valid_21626900, JString, required = true, default = newJString(
      "StarlingDoveService.PutAggregationAuthorization"))
  if valid_21626900 != nil:
    section.add "X-Amz-Target", valid_21626900
  var valid_21626901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626901 = validateParameter(valid_21626901, JString, required = false,
                                   default = nil)
  if valid_21626901 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626901
  var valid_21626902 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626902 = validateParameter(valid_21626902, JString, required = false,
                                   default = nil)
  if valid_21626902 != nil:
    section.add "X-Amz-Algorithm", valid_21626902
  var valid_21626903 = header.getOrDefault("X-Amz-Signature")
  valid_21626903 = validateParameter(valid_21626903, JString, required = false,
                                   default = nil)
  if valid_21626903 != nil:
    section.add "X-Amz-Signature", valid_21626903
  var valid_21626904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626904 = validateParameter(valid_21626904, JString, required = false,
                                   default = nil)
  if valid_21626904 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626904
  var valid_21626905 = header.getOrDefault("X-Amz-Credential")
  valid_21626905 = validateParameter(valid_21626905, JString, required = false,
                                   default = nil)
  if valid_21626905 != nil:
    section.add "X-Amz-Credential", valid_21626905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626907: Call_PutAggregationAuthorization_21626895;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Authorizes the aggregator account and region to collect data from the source account and region. 
  ## 
  let valid = call_21626907.validator(path, query, header, formData, body, _)
  let scheme = call_21626907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626907.makeUrl(scheme.get, call_21626907.host, call_21626907.base,
                               call_21626907.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626907, uri, valid, _)

proc call*(call_21626908: Call_PutAggregationAuthorization_21626895; body: JsonNode): Recallable =
  ## putAggregationAuthorization
  ## Authorizes the aggregator account and region to collect data from the source account and region. 
  ##   body: JObject (required)
  var body_21626909 = newJObject()
  if body != nil:
    body_21626909 = body
  result = call_21626908.call(nil, nil, nil, nil, body_21626909)

var putAggregationAuthorization* = Call_PutAggregationAuthorization_21626895(
    name: "putAggregationAuthorization", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutAggregationAuthorization",
    validator: validate_PutAggregationAuthorization_21626896, base: "/",
    makeUrl: url_PutAggregationAuthorization_21626897,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigRule_21626910 = ref object of OpenApiRestCall_21625435
proc url_PutConfigRule_21626912(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutConfigRule_21626911(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Adds or updates an AWS Config rule for evaluating whether your AWS resources comply with your desired configurations.</p> <p>You can use this action for custom AWS Config rules and AWS managed Config rules. A custom AWS Config rule is a rule that you develop and maintain. An AWS managed Config rule is a customizable, predefined rule that AWS Config provides.</p> <p>If you are adding a new custom AWS Config rule, you must first create the AWS Lambda function that the rule invokes to evaluate your resources. When you use the <code>PutConfigRule</code> action to add the rule to AWS Config, you must specify the Amazon Resource Name (ARN) that AWS Lambda assigns to the function. Specify the ARN for the <code>SourceIdentifier</code> key. This key is part of the <code>Source</code> object, which is part of the <code>ConfigRule</code> object. </p> <p>If you are adding an AWS managed Config rule, specify the rule's identifier for the <code>SourceIdentifier</code> key. To reference AWS managed Config rule identifiers, see <a href="https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config_use-managed-rules.html">About AWS Managed Config Rules</a>.</p> <p>For any new rule that you add, specify the <code>ConfigRuleName</code> in the <code>ConfigRule</code> object. Do not specify the <code>ConfigRuleArn</code> or the <code>ConfigRuleId</code>. These values are generated by AWS Config for new rules.</p> <p>If you are updating a rule that you added previously, you can specify the rule by <code>ConfigRuleName</code>, <code>ConfigRuleId</code>, or <code>ConfigRuleArn</code> in the <code>ConfigRule</code> data type that you use in this request.</p> <p>The maximum number of rules that AWS Config supports is 150.</p> <p>For information about requesting a rule limit increase, see <a href="http://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_config">AWS Config Limits</a> in the <i>AWS General Reference Guide</i>.</p> <p>For more information about developing and using AWS Config rules, see <a href="https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config.html">Evaluating AWS Resource Configurations with AWS Config</a> in the <i>AWS Config Developer Guide</i>.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626913 = header.getOrDefault("X-Amz-Date")
  valid_21626913 = validateParameter(valid_21626913, JString, required = false,
                                   default = nil)
  if valid_21626913 != nil:
    section.add "X-Amz-Date", valid_21626913
  var valid_21626914 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626914 = validateParameter(valid_21626914, JString, required = false,
                                   default = nil)
  if valid_21626914 != nil:
    section.add "X-Amz-Security-Token", valid_21626914
  var valid_21626915 = header.getOrDefault("X-Amz-Target")
  valid_21626915 = validateParameter(valid_21626915, JString, required = true, default = newJString(
      "StarlingDoveService.PutConfigRule"))
  if valid_21626915 != nil:
    section.add "X-Amz-Target", valid_21626915
  var valid_21626916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626916 = validateParameter(valid_21626916, JString, required = false,
                                   default = nil)
  if valid_21626916 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626916
  var valid_21626917 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626917 = validateParameter(valid_21626917, JString, required = false,
                                   default = nil)
  if valid_21626917 != nil:
    section.add "X-Amz-Algorithm", valid_21626917
  var valid_21626918 = header.getOrDefault("X-Amz-Signature")
  valid_21626918 = validateParameter(valid_21626918, JString, required = false,
                                   default = nil)
  if valid_21626918 != nil:
    section.add "X-Amz-Signature", valid_21626918
  var valid_21626919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626919 = validateParameter(valid_21626919, JString, required = false,
                                   default = nil)
  if valid_21626919 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626919
  var valid_21626920 = header.getOrDefault("X-Amz-Credential")
  valid_21626920 = validateParameter(valid_21626920, JString, required = false,
                                   default = nil)
  if valid_21626920 != nil:
    section.add "X-Amz-Credential", valid_21626920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626922: Call_PutConfigRule_21626910; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds or updates an AWS Config rule for evaluating whether your AWS resources comply with your desired configurations.</p> <p>You can use this action for custom AWS Config rules and AWS managed Config rules. A custom AWS Config rule is a rule that you develop and maintain. An AWS managed Config rule is a customizable, predefined rule that AWS Config provides.</p> <p>If you are adding a new custom AWS Config rule, you must first create the AWS Lambda function that the rule invokes to evaluate your resources. When you use the <code>PutConfigRule</code> action to add the rule to AWS Config, you must specify the Amazon Resource Name (ARN) that AWS Lambda assigns to the function. Specify the ARN for the <code>SourceIdentifier</code> key. This key is part of the <code>Source</code> object, which is part of the <code>ConfigRule</code> object. </p> <p>If you are adding an AWS managed Config rule, specify the rule's identifier for the <code>SourceIdentifier</code> key. To reference AWS managed Config rule identifiers, see <a href="https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config_use-managed-rules.html">About AWS Managed Config Rules</a>.</p> <p>For any new rule that you add, specify the <code>ConfigRuleName</code> in the <code>ConfigRule</code> object. Do not specify the <code>ConfigRuleArn</code> or the <code>ConfigRuleId</code>. These values are generated by AWS Config for new rules.</p> <p>If you are updating a rule that you added previously, you can specify the rule by <code>ConfigRuleName</code>, <code>ConfigRuleId</code>, or <code>ConfigRuleArn</code> in the <code>ConfigRule</code> data type that you use in this request.</p> <p>The maximum number of rules that AWS Config supports is 150.</p> <p>For information about requesting a rule limit increase, see <a href="http://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_config">AWS Config Limits</a> in the <i>AWS General Reference Guide</i>.</p> <p>For more information about developing and using AWS Config rules, see <a href="https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config.html">Evaluating AWS Resource Configurations with AWS Config</a> in the <i>AWS Config Developer Guide</i>.</p>
  ## 
  let valid = call_21626922.validator(path, query, header, formData, body, _)
  let scheme = call_21626922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626922.makeUrl(scheme.get, call_21626922.host, call_21626922.base,
                               call_21626922.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626922, uri, valid, _)

proc call*(call_21626923: Call_PutConfigRule_21626910; body: JsonNode): Recallable =
  ## putConfigRule
  ## <p>Adds or updates an AWS Config rule for evaluating whether your AWS resources comply with your desired configurations.</p> <p>You can use this action for custom AWS Config rules and AWS managed Config rules. A custom AWS Config rule is a rule that you develop and maintain. An AWS managed Config rule is a customizable, predefined rule that AWS Config provides.</p> <p>If you are adding a new custom AWS Config rule, you must first create the AWS Lambda function that the rule invokes to evaluate your resources. When you use the <code>PutConfigRule</code> action to add the rule to AWS Config, you must specify the Amazon Resource Name (ARN) that AWS Lambda assigns to the function. Specify the ARN for the <code>SourceIdentifier</code> key. This key is part of the <code>Source</code> object, which is part of the <code>ConfigRule</code> object. </p> <p>If you are adding an AWS managed Config rule, specify the rule's identifier for the <code>SourceIdentifier</code> key. To reference AWS managed Config rule identifiers, see <a href="https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config_use-managed-rules.html">About AWS Managed Config Rules</a>.</p> <p>For any new rule that you add, specify the <code>ConfigRuleName</code> in the <code>ConfigRule</code> object. Do not specify the <code>ConfigRuleArn</code> or the <code>ConfigRuleId</code>. These values are generated by AWS Config for new rules.</p> <p>If you are updating a rule that you added previously, you can specify the rule by <code>ConfigRuleName</code>, <code>ConfigRuleId</code>, or <code>ConfigRuleArn</code> in the <code>ConfigRule</code> data type that you use in this request.</p> <p>The maximum number of rules that AWS Config supports is 150.</p> <p>For information about requesting a rule limit increase, see <a href="http://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_config">AWS Config Limits</a> in the <i>AWS General Reference Guide</i>.</p> <p>For more information about developing and using AWS Config rules, see <a href="https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config.html">Evaluating AWS Resource Configurations with AWS Config</a> in the <i>AWS Config Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_21626924 = newJObject()
  if body != nil:
    body_21626924 = body
  result = call_21626923.call(nil, nil, nil, nil, body_21626924)

var putConfigRule* = Call_PutConfigRule_21626910(name: "putConfigRule",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutConfigRule",
    validator: validate_PutConfigRule_21626911, base: "/",
    makeUrl: url_PutConfigRule_21626912, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationAggregator_21626925 = ref object of OpenApiRestCall_21625435
proc url_PutConfigurationAggregator_21626927(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutConfigurationAggregator_21626926(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates and updates the configuration aggregator with the selected source accounts and regions. The source account can be individual account(s) or an organization.</p> <note> <p>AWS Config should be enabled in source accounts and regions you want to aggregate.</p> <p>If your source type is an organization, you must be signed in to the master account and all features must be enabled in your organization. AWS Config calls <code>EnableAwsServiceAccess</code> API to enable integration between AWS Config and AWS Organizations. </p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626928 = header.getOrDefault("X-Amz-Date")
  valid_21626928 = validateParameter(valid_21626928, JString, required = false,
                                   default = nil)
  if valid_21626928 != nil:
    section.add "X-Amz-Date", valid_21626928
  var valid_21626929 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626929 = validateParameter(valid_21626929, JString, required = false,
                                   default = nil)
  if valid_21626929 != nil:
    section.add "X-Amz-Security-Token", valid_21626929
  var valid_21626930 = header.getOrDefault("X-Amz-Target")
  valid_21626930 = validateParameter(valid_21626930, JString, required = true, default = newJString(
      "StarlingDoveService.PutConfigurationAggregator"))
  if valid_21626930 != nil:
    section.add "X-Amz-Target", valid_21626930
  var valid_21626931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626931 = validateParameter(valid_21626931, JString, required = false,
                                   default = nil)
  if valid_21626931 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626931
  var valid_21626932 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626932 = validateParameter(valid_21626932, JString, required = false,
                                   default = nil)
  if valid_21626932 != nil:
    section.add "X-Amz-Algorithm", valid_21626932
  var valid_21626933 = header.getOrDefault("X-Amz-Signature")
  valid_21626933 = validateParameter(valid_21626933, JString, required = false,
                                   default = nil)
  if valid_21626933 != nil:
    section.add "X-Amz-Signature", valid_21626933
  var valid_21626934 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626934 = validateParameter(valid_21626934, JString, required = false,
                                   default = nil)
  if valid_21626934 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626934
  var valid_21626935 = header.getOrDefault("X-Amz-Credential")
  valid_21626935 = validateParameter(valid_21626935, JString, required = false,
                                   default = nil)
  if valid_21626935 != nil:
    section.add "X-Amz-Credential", valid_21626935
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626937: Call_PutConfigurationAggregator_21626925;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates and updates the configuration aggregator with the selected source accounts and regions. The source account can be individual account(s) or an organization.</p> <note> <p>AWS Config should be enabled in source accounts and regions you want to aggregate.</p> <p>If your source type is an organization, you must be signed in to the master account and all features must be enabled in your organization. AWS Config calls <code>EnableAwsServiceAccess</code> API to enable integration between AWS Config and AWS Organizations. </p> </note>
  ## 
  let valid = call_21626937.validator(path, query, header, formData, body, _)
  let scheme = call_21626937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626937.makeUrl(scheme.get, call_21626937.host, call_21626937.base,
                               call_21626937.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626937, uri, valid, _)

proc call*(call_21626938: Call_PutConfigurationAggregator_21626925; body: JsonNode): Recallable =
  ## putConfigurationAggregator
  ## <p>Creates and updates the configuration aggregator with the selected source accounts and regions. The source account can be individual account(s) or an organization.</p> <note> <p>AWS Config should be enabled in source accounts and regions you want to aggregate.</p> <p>If your source type is an organization, you must be signed in to the master account and all features must be enabled in your organization. AWS Config calls <code>EnableAwsServiceAccess</code> API to enable integration between AWS Config and AWS Organizations. </p> </note>
  ##   body: JObject (required)
  var body_21626939 = newJObject()
  if body != nil:
    body_21626939 = body
  result = call_21626938.call(nil, nil, nil, nil, body_21626939)

var putConfigurationAggregator* = Call_PutConfigurationAggregator_21626925(
    name: "putConfigurationAggregator", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutConfigurationAggregator",
    validator: validate_PutConfigurationAggregator_21626926, base: "/",
    makeUrl: url_PutConfigurationAggregator_21626927,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationRecorder_21626940 = ref object of OpenApiRestCall_21625435
proc url_PutConfigurationRecorder_21626942(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutConfigurationRecorder_21626941(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a new configuration recorder to record the selected resource configurations.</p> <p>You can use this action to change the role <code>roleARN</code> or the <code>recordingGroup</code> of an existing recorder. To change the role, call the action on the existing configuration recorder and specify a role.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> <p>If <code>ConfigurationRecorder</code> does not have the <b>recordingGroup</b> parameter specified, the default is to record all supported resource types.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626943 = header.getOrDefault("X-Amz-Date")
  valid_21626943 = validateParameter(valid_21626943, JString, required = false,
                                   default = nil)
  if valid_21626943 != nil:
    section.add "X-Amz-Date", valid_21626943
  var valid_21626944 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626944 = validateParameter(valid_21626944, JString, required = false,
                                   default = nil)
  if valid_21626944 != nil:
    section.add "X-Amz-Security-Token", valid_21626944
  var valid_21626945 = header.getOrDefault("X-Amz-Target")
  valid_21626945 = validateParameter(valid_21626945, JString, required = true, default = newJString(
      "StarlingDoveService.PutConfigurationRecorder"))
  if valid_21626945 != nil:
    section.add "X-Amz-Target", valid_21626945
  var valid_21626946 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626946 = validateParameter(valid_21626946, JString, required = false,
                                   default = nil)
  if valid_21626946 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626946
  var valid_21626947 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626947 = validateParameter(valid_21626947, JString, required = false,
                                   default = nil)
  if valid_21626947 != nil:
    section.add "X-Amz-Algorithm", valid_21626947
  var valid_21626948 = header.getOrDefault("X-Amz-Signature")
  valid_21626948 = validateParameter(valid_21626948, JString, required = false,
                                   default = nil)
  if valid_21626948 != nil:
    section.add "X-Amz-Signature", valid_21626948
  var valid_21626949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626949 = validateParameter(valid_21626949, JString, required = false,
                                   default = nil)
  if valid_21626949 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626949
  var valid_21626950 = header.getOrDefault("X-Amz-Credential")
  valid_21626950 = validateParameter(valid_21626950, JString, required = false,
                                   default = nil)
  if valid_21626950 != nil:
    section.add "X-Amz-Credential", valid_21626950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626952: Call_PutConfigurationRecorder_21626940;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new configuration recorder to record the selected resource configurations.</p> <p>You can use this action to change the role <code>roleARN</code> or the <code>recordingGroup</code> of an existing recorder. To change the role, call the action on the existing configuration recorder and specify a role.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> <p>If <code>ConfigurationRecorder</code> does not have the <b>recordingGroup</b> parameter specified, the default is to record all supported resource types.</p> </note>
  ## 
  let valid = call_21626952.validator(path, query, header, formData, body, _)
  let scheme = call_21626952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626952.makeUrl(scheme.get, call_21626952.host, call_21626952.base,
                               call_21626952.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626952, uri, valid, _)

proc call*(call_21626953: Call_PutConfigurationRecorder_21626940; body: JsonNode): Recallable =
  ## putConfigurationRecorder
  ## <p>Creates a new configuration recorder to record the selected resource configurations.</p> <p>You can use this action to change the role <code>roleARN</code> or the <code>recordingGroup</code> of an existing recorder. To change the role, call the action on the existing configuration recorder and specify a role.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> <p>If <code>ConfigurationRecorder</code> does not have the <b>recordingGroup</b> parameter specified, the default is to record all supported resource types.</p> </note>
  ##   body: JObject (required)
  var body_21626954 = newJObject()
  if body != nil:
    body_21626954 = body
  result = call_21626953.call(nil, nil, nil, nil, body_21626954)

var putConfigurationRecorder* = Call_PutConfigurationRecorder_21626940(
    name: "putConfigurationRecorder", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutConfigurationRecorder",
    validator: validate_PutConfigurationRecorder_21626941, base: "/",
    makeUrl: url_PutConfigurationRecorder_21626942,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConformancePack_21626955 = ref object of OpenApiRestCall_21625435
proc url_PutConformancePack_21626957(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutConformancePack_21626956(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates or updates a conformance pack. A conformance pack is a collection of AWS Config rules that can be easily deployed in an account and a region and across AWS Organization.</p> <p>This API creates a service linked role <code>AWSServiceRoleForConfigConforms</code> in your account. The service linked role is created only when the role does not exist in your account. AWS Config verifies the existence of role with <code>GetRole</code> action.</p> <note> <p>You must specify either the <code>TemplateS3Uri</code> or the <code>TemplateBody</code> parameter, but not both. If you provide both AWS Config uses the <code>TemplateS3Uri</code> parameter and ignores the <code>TemplateBody</code> parameter.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626958 = header.getOrDefault("X-Amz-Date")
  valid_21626958 = validateParameter(valid_21626958, JString, required = false,
                                   default = nil)
  if valid_21626958 != nil:
    section.add "X-Amz-Date", valid_21626958
  var valid_21626959 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626959 = validateParameter(valid_21626959, JString, required = false,
                                   default = nil)
  if valid_21626959 != nil:
    section.add "X-Amz-Security-Token", valid_21626959
  var valid_21626960 = header.getOrDefault("X-Amz-Target")
  valid_21626960 = validateParameter(valid_21626960, JString, required = true, default = newJString(
      "StarlingDoveService.PutConformancePack"))
  if valid_21626960 != nil:
    section.add "X-Amz-Target", valid_21626960
  var valid_21626961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626961 = validateParameter(valid_21626961, JString, required = false,
                                   default = nil)
  if valid_21626961 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626961
  var valid_21626962 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626962 = validateParameter(valid_21626962, JString, required = false,
                                   default = nil)
  if valid_21626962 != nil:
    section.add "X-Amz-Algorithm", valid_21626962
  var valid_21626963 = header.getOrDefault("X-Amz-Signature")
  valid_21626963 = validateParameter(valid_21626963, JString, required = false,
                                   default = nil)
  if valid_21626963 != nil:
    section.add "X-Amz-Signature", valid_21626963
  var valid_21626964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626964 = validateParameter(valid_21626964, JString, required = false,
                                   default = nil)
  if valid_21626964 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626964
  var valid_21626965 = header.getOrDefault("X-Amz-Credential")
  valid_21626965 = validateParameter(valid_21626965, JString, required = false,
                                   default = nil)
  if valid_21626965 != nil:
    section.add "X-Amz-Credential", valid_21626965
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626967: Call_PutConformancePack_21626955; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates or updates a conformance pack. A conformance pack is a collection of AWS Config rules that can be easily deployed in an account and a region and across AWS Organization.</p> <p>This API creates a service linked role <code>AWSServiceRoleForConfigConforms</code> in your account. The service linked role is created only when the role does not exist in your account. AWS Config verifies the existence of role with <code>GetRole</code> action.</p> <note> <p>You must specify either the <code>TemplateS3Uri</code> or the <code>TemplateBody</code> parameter, but not both. If you provide both AWS Config uses the <code>TemplateS3Uri</code> parameter and ignores the <code>TemplateBody</code> parameter.</p> </note>
  ## 
  let valid = call_21626967.validator(path, query, header, formData, body, _)
  let scheme = call_21626967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626967.makeUrl(scheme.get, call_21626967.host, call_21626967.base,
                               call_21626967.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626967, uri, valid, _)

proc call*(call_21626968: Call_PutConformancePack_21626955; body: JsonNode): Recallable =
  ## putConformancePack
  ## <p>Creates or updates a conformance pack. A conformance pack is a collection of AWS Config rules that can be easily deployed in an account and a region and across AWS Organization.</p> <p>This API creates a service linked role <code>AWSServiceRoleForConfigConforms</code> in your account. The service linked role is created only when the role does not exist in your account. AWS Config verifies the existence of role with <code>GetRole</code> action.</p> <note> <p>You must specify either the <code>TemplateS3Uri</code> or the <code>TemplateBody</code> parameter, but not both. If you provide both AWS Config uses the <code>TemplateS3Uri</code> parameter and ignores the <code>TemplateBody</code> parameter.</p> </note>
  ##   body: JObject (required)
  var body_21626969 = newJObject()
  if body != nil:
    body_21626969 = body
  result = call_21626968.call(nil, nil, nil, nil, body_21626969)

var putConformancePack* = Call_PutConformancePack_21626955(
    name: "putConformancePack", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutConformancePack",
    validator: validate_PutConformancePack_21626956, base: "/",
    makeUrl: url_PutConformancePack_21626957, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDeliveryChannel_21626970 = ref object of OpenApiRestCall_21625435
proc url_PutDeliveryChannel_21626972(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutDeliveryChannel_21626971(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a delivery channel object to deliver configuration information to an Amazon S3 bucket and Amazon SNS topic.</p> <p>Before you can create a delivery channel, you must create a configuration recorder.</p> <p>You can use this action to change the Amazon S3 bucket or an Amazon SNS topic of the existing delivery channel. To change the Amazon S3 bucket or an Amazon SNS topic, call this action and specify the changed values for the S3 bucket and the SNS topic. If you specify a different value for either the S3 bucket or the SNS topic, this action will keep the existing value for the parameter that is not changed.</p> <note> <p>You can have only one delivery channel per region in your account.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626973 = header.getOrDefault("X-Amz-Date")
  valid_21626973 = validateParameter(valid_21626973, JString, required = false,
                                   default = nil)
  if valid_21626973 != nil:
    section.add "X-Amz-Date", valid_21626973
  var valid_21626974 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626974 = validateParameter(valid_21626974, JString, required = false,
                                   default = nil)
  if valid_21626974 != nil:
    section.add "X-Amz-Security-Token", valid_21626974
  var valid_21626975 = header.getOrDefault("X-Amz-Target")
  valid_21626975 = validateParameter(valid_21626975, JString, required = true, default = newJString(
      "StarlingDoveService.PutDeliveryChannel"))
  if valid_21626975 != nil:
    section.add "X-Amz-Target", valid_21626975
  var valid_21626976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626976 = validateParameter(valid_21626976, JString, required = false,
                                   default = nil)
  if valid_21626976 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626976
  var valid_21626977 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626977 = validateParameter(valid_21626977, JString, required = false,
                                   default = nil)
  if valid_21626977 != nil:
    section.add "X-Amz-Algorithm", valid_21626977
  var valid_21626978 = header.getOrDefault("X-Amz-Signature")
  valid_21626978 = validateParameter(valid_21626978, JString, required = false,
                                   default = nil)
  if valid_21626978 != nil:
    section.add "X-Amz-Signature", valid_21626978
  var valid_21626979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626979 = validateParameter(valid_21626979, JString, required = false,
                                   default = nil)
  if valid_21626979 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626979
  var valid_21626980 = header.getOrDefault("X-Amz-Credential")
  valid_21626980 = validateParameter(valid_21626980, JString, required = false,
                                   default = nil)
  if valid_21626980 != nil:
    section.add "X-Amz-Credential", valid_21626980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626982: Call_PutDeliveryChannel_21626970; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a delivery channel object to deliver configuration information to an Amazon S3 bucket and Amazon SNS topic.</p> <p>Before you can create a delivery channel, you must create a configuration recorder.</p> <p>You can use this action to change the Amazon S3 bucket or an Amazon SNS topic of the existing delivery channel. To change the Amazon S3 bucket or an Amazon SNS topic, call this action and specify the changed values for the S3 bucket and the SNS topic. If you specify a different value for either the S3 bucket or the SNS topic, this action will keep the existing value for the parameter that is not changed.</p> <note> <p>You can have only one delivery channel per region in your account.</p> </note>
  ## 
  let valid = call_21626982.validator(path, query, header, formData, body, _)
  let scheme = call_21626982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626982.makeUrl(scheme.get, call_21626982.host, call_21626982.base,
                               call_21626982.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626982, uri, valid, _)

proc call*(call_21626983: Call_PutDeliveryChannel_21626970; body: JsonNode): Recallable =
  ## putDeliveryChannel
  ## <p>Creates a delivery channel object to deliver configuration information to an Amazon S3 bucket and Amazon SNS topic.</p> <p>Before you can create a delivery channel, you must create a configuration recorder.</p> <p>You can use this action to change the Amazon S3 bucket or an Amazon SNS topic of the existing delivery channel. To change the Amazon S3 bucket or an Amazon SNS topic, call this action and specify the changed values for the S3 bucket and the SNS topic. If you specify a different value for either the S3 bucket or the SNS topic, this action will keep the existing value for the parameter that is not changed.</p> <note> <p>You can have only one delivery channel per region in your account.</p> </note>
  ##   body: JObject (required)
  var body_21626984 = newJObject()
  if body != nil:
    body_21626984 = body
  result = call_21626983.call(nil, nil, nil, nil, body_21626984)

var putDeliveryChannel* = Call_PutDeliveryChannel_21626970(
    name: "putDeliveryChannel", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutDeliveryChannel",
    validator: validate_PutDeliveryChannel_21626971, base: "/",
    makeUrl: url_PutDeliveryChannel_21626972, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEvaluations_21626985 = ref object of OpenApiRestCall_21625435
proc url_PutEvaluations_21626987(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutEvaluations_21626986(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Used by an AWS Lambda function to deliver evaluation results to AWS Config. This action is required in every AWS Lambda function that is invoked by an AWS Config rule.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626988 = header.getOrDefault("X-Amz-Date")
  valid_21626988 = validateParameter(valid_21626988, JString, required = false,
                                   default = nil)
  if valid_21626988 != nil:
    section.add "X-Amz-Date", valid_21626988
  var valid_21626989 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626989 = validateParameter(valid_21626989, JString, required = false,
                                   default = nil)
  if valid_21626989 != nil:
    section.add "X-Amz-Security-Token", valid_21626989
  var valid_21626990 = header.getOrDefault("X-Amz-Target")
  valid_21626990 = validateParameter(valid_21626990, JString, required = true, default = newJString(
      "StarlingDoveService.PutEvaluations"))
  if valid_21626990 != nil:
    section.add "X-Amz-Target", valid_21626990
  var valid_21626991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626991 = validateParameter(valid_21626991, JString, required = false,
                                   default = nil)
  if valid_21626991 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626991
  var valid_21626992 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626992 = validateParameter(valid_21626992, JString, required = false,
                                   default = nil)
  if valid_21626992 != nil:
    section.add "X-Amz-Algorithm", valid_21626992
  var valid_21626993 = header.getOrDefault("X-Amz-Signature")
  valid_21626993 = validateParameter(valid_21626993, JString, required = false,
                                   default = nil)
  if valid_21626993 != nil:
    section.add "X-Amz-Signature", valid_21626993
  var valid_21626994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626994 = validateParameter(valid_21626994, JString, required = false,
                                   default = nil)
  if valid_21626994 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626994
  var valid_21626995 = header.getOrDefault("X-Amz-Credential")
  valid_21626995 = validateParameter(valid_21626995, JString, required = false,
                                   default = nil)
  if valid_21626995 != nil:
    section.add "X-Amz-Credential", valid_21626995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626997: Call_PutEvaluations_21626985; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Used by an AWS Lambda function to deliver evaluation results to AWS Config. This action is required in every AWS Lambda function that is invoked by an AWS Config rule.
  ## 
  let valid = call_21626997.validator(path, query, header, formData, body, _)
  let scheme = call_21626997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626997.makeUrl(scheme.get, call_21626997.host, call_21626997.base,
                               call_21626997.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626997, uri, valid, _)

proc call*(call_21626998: Call_PutEvaluations_21626985; body: JsonNode): Recallable =
  ## putEvaluations
  ## Used by an AWS Lambda function to deliver evaluation results to AWS Config. This action is required in every AWS Lambda function that is invoked by an AWS Config rule.
  ##   body: JObject (required)
  var body_21626999 = newJObject()
  if body != nil:
    body_21626999 = body
  result = call_21626998.call(nil, nil, nil, nil, body_21626999)

var putEvaluations* = Call_PutEvaluations_21626985(name: "putEvaluations",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutEvaluations",
    validator: validate_PutEvaluations_21626986, base: "/",
    makeUrl: url_PutEvaluations_21626987, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutOrganizationConfigRule_21627000 = ref object of OpenApiRestCall_21625435
proc url_PutOrganizationConfigRule_21627002(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutOrganizationConfigRule_21627001(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Adds or updates organization config rule for your entire organization evaluating whether your AWS resources comply with your desired configurations. Only a master account can create or update an organization config rule.</p> <p>This API enables organization service access through the <code>EnableAWSServiceAccess</code> action and creates a service linked role <code>AWSServiceRoleForConfigMultiAccountSetup</code> in the master account of your organization. The service linked role is created only when the role does not exist in the master account. AWS Config verifies the existence of role with <code>GetRole</code> action.</p> <p>You can use this action to create both custom AWS Config rules and AWS managed Config rules. If you are adding a new custom AWS Config rule, you must first create AWS Lambda function in the master account that the rule invokes to evaluate your resources. When you use the <code>PutOrganizationConfigRule</code> action to add the rule to AWS Config, you must specify the Amazon Resource Name (ARN) that AWS Lambda assigns to the function. If you are adding an AWS managed Config rule, specify the rule's identifier for the <code>RuleIdentifier</code> key.</p> <p>The maximum number of organization config rules that AWS Config supports is 150.</p> <note> <p>Specify either <code>OrganizationCustomRuleMetadata</code> or <code>OrganizationManagedRuleMetadata</code>.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627003 = header.getOrDefault("X-Amz-Date")
  valid_21627003 = validateParameter(valid_21627003, JString, required = false,
                                   default = nil)
  if valid_21627003 != nil:
    section.add "X-Amz-Date", valid_21627003
  var valid_21627004 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627004 = validateParameter(valid_21627004, JString, required = false,
                                   default = nil)
  if valid_21627004 != nil:
    section.add "X-Amz-Security-Token", valid_21627004
  var valid_21627005 = header.getOrDefault("X-Amz-Target")
  valid_21627005 = validateParameter(valid_21627005, JString, required = true, default = newJString(
      "StarlingDoveService.PutOrganizationConfigRule"))
  if valid_21627005 != nil:
    section.add "X-Amz-Target", valid_21627005
  var valid_21627006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627006 = validateParameter(valid_21627006, JString, required = false,
                                   default = nil)
  if valid_21627006 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627006
  var valid_21627007 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627007 = validateParameter(valid_21627007, JString, required = false,
                                   default = nil)
  if valid_21627007 != nil:
    section.add "X-Amz-Algorithm", valid_21627007
  var valid_21627008 = header.getOrDefault("X-Amz-Signature")
  valid_21627008 = validateParameter(valid_21627008, JString, required = false,
                                   default = nil)
  if valid_21627008 != nil:
    section.add "X-Amz-Signature", valid_21627008
  var valid_21627009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627009 = validateParameter(valid_21627009, JString, required = false,
                                   default = nil)
  if valid_21627009 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627009
  var valid_21627010 = header.getOrDefault("X-Amz-Credential")
  valid_21627010 = validateParameter(valid_21627010, JString, required = false,
                                   default = nil)
  if valid_21627010 != nil:
    section.add "X-Amz-Credential", valid_21627010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627012: Call_PutOrganizationConfigRule_21627000;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds or updates organization config rule for your entire organization evaluating whether your AWS resources comply with your desired configurations. Only a master account can create or update an organization config rule.</p> <p>This API enables organization service access through the <code>EnableAWSServiceAccess</code> action and creates a service linked role <code>AWSServiceRoleForConfigMultiAccountSetup</code> in the master account of your organization. The service linked role is created only when the role does not exist in the master account. AWS Config verifies the existence of role with <code>GetRole</code> action.</p> <p>You can use this action to create both custom AWS Config rules and AWS managed Config rules. If you are adding a new custom AWS Config rule, you must first create AWS Lambda function in the master account that the rule invokes to evaluate your resources. When you use the <code>PutOrganizationConfigRule</code> action to add the rule to AWS Config, you must specify the Amazon Resource Name (ARN) that AWS Lambda assigns to the function. If you are adding an AWS managed Config rule, specify the rule's identifier for the <code>RuleIdentifier</code> key.</p> <p>The maximum number of organization config rules that AWS Config supports is 150.</p> <note> <p>Specify either <code>OrganizationCustomRuleMetadata</code> or <code>OrganizationManagedRuleMetadata</code>.</p> </note>
  ## 
  let valid = call_21627012.validator(path, query, header, formData, body, _)
  let scheme = call_21627012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627012.makeUrl(scheme.get, call_21627012.host, call_21627012.base,
                               call_21627012.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627012, uri, valid, _)

proc call*(call_21627013: Call_PutOrganizationConfigRule_21627000; body: JsonNode): Recallable =
  ## putOrganizationConfigRule
  ## <p>Adds or updates organization config rule for your entire organization evaluating whether your AWS resources comply with your desired configurations. Only a master account can create or update an organization config rule.</p> <p>This API enables organization service access through the <code>EnableAWSServiceAccess</code> action and creates a service linked role <code>AWSServiceRoleForConfigMultiAccountSetup</code> in the master account of your organization. The service linked role is created only when the role does not exist in the master account. AWS Config verifies the existence of role with <code>GetRole</code> action.</p> <p>You can use this action to create both custom AWS Config rules and AWS managed Config rules. If you are adding a new custom AWS Config rule, you must first create AWS Lambda function in the master account that the rule invokes to evaluate your resources. When you use the <code>PutOrganizationConfigRule</code> action to add the rule to AWS Config, you must specify the Amazon Resource Name (ARN) that AWS Lambda assigns to the function. If you are adding an AWS managed Config rule, specify the rule's identifier for the <code>RuleIdentifier</code> key.</p> <p>The maximum number of organization config rules that AWS Config supports is 150.</p> <note> <p>Specify either <code>OrganizationCustomRuleMetadata</code> or <code>OrganizationManagedRuleMetadata</code>.</p> </note>
  ##   body: JObject (required)
  var body_21627014 = newJObject()
  if body != nil:
    body_21627014 = body
  result = call_21627013.call(nil, nil, nil, nil, body_21627014)

var putOrganizationConfigRule* = Call_PutOrganizationConfigRule_21627000(
    name: "putOrganizationConfigRule", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutOrganizationConfigRule",
    validator: validate_PutOrganizationConfigRule_21627001, base: "/",
    makeUrl: url_PutOrganizationConfigRule_21627002,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutOrganizationConformancePack_21627015 = ref object of OpenApiRestCall_21625435
proc url_PutOrganizationConformancePack_21627017(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutOrganizationConformancePack_21627016(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Deploys conformance packs across member accounts in an AWS Organization.</p> <p>This API enables organization service access for <code>config-multiaccountsetup.amazonaws.com</code> through the <code>EnableAWSServiceAccess</code> action and creates a service linked role <code>AWSServiceRoleForConfigMultiAccountSetup</code> in the master account of your organization. The service linked role is created only when the role does not exist in the master account. AWS Config verifies the existence of role with GetRole action.</p> <note> <p>You must specify either the <code>TemplateS3Uri</code> or the <code>TemplateBody</code> parameter, but not both. If you provide both AWS Config uses the <code>TemplateS3Uri</code> parameter and ignores the <code>TemplateBody</code> parameter.</p> <p>AWS Config sets the state of a conformance pack to CREATE_IN_PROGRESS and UPDATE_IN_PROGRESS until the confomance pack is created or updated. You cannot update a conformance pack while it is in this state.</p> <p>You can create 6 conformance packs with 25 AWS Config rules in each pack.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627018 = header.getOrDefault("X-Amz-Date")
  valid_21627018 = validateParameter(valid_21627018, JString, required = false,
                                   default = nil)
  if valid_21627018 != nil:
    section.add "X-Amz-Date", valid_21627018
  var valid_21627019 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627019 = validateParameter(valid_21627019, JString, required = false,
                                   default = nil)
  if valid_21627019 != nil:
    section.add "X-Amz-Security-Token", valid_21627019
  var valid_21627020 = header.getOrDefault("X-Amz-Target")
  valid_21627020 = validateParameter(valid_21627020, JString, required = true, default = newJString(
      "StarlingDoveService.PutOrganizationConformancePack"))
  if valid_21627020 != nil:
    section.add "X-Amz-Target", valid_21627020
  var valid_21627021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627021 = validateParameter(valid_21627021, JString, required = false,
                                   default = nil)
  if valid_21627021 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627021
  var valid_21627022 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627022 = validateParameter(valid_21627022, JString, required = false,
                                   default = nil)
  if valid_21627022 != nil:
    section.add "X-Amz-Algorithm", valid_21627022
  var valid_21627023 = header.getOrDefault("X-Amz-Signature")
  valid_21627023 = validateParameter(valid_21627023, JString, required = false,
                                   default = nil)
  if valid_21627023 != nil:
    section.add "X-Amz-Signature", valid_21627023
  var valid_21627024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627024 = validateParameter(valid_21627024, JString, required = false,
                                   default = nil)
  if valid_21627024 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627024
  var valid_21627025 = header.getOrDefault("X-Amz-Credential")
  valid_21627025 = validateParameter(valid_21627025, JString, required = false,
                                   default = nil)
  if valid_21627025 != nil:
    section.add "X-Amz-Credential", valid_21627025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627027: Call_PutOrganizationConformancePack_21627015;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deploys conformance packs across member accounts in an AWS Organization.</p> <p>This API enables organization service access for <code>config-multiaccountsetup.amazonaws.com</code> through the <code>EnableAWSServiceAccess</code> action and creates a service linked role <code>AWSServiceRoleForConfigMultiAccountSetup</code> in the master account of your organization. The service linked role is created only when the role does not exist in the master account. AWS Config verifies the existence of role with GetRole action.</p> <note> <p>You must specify either the <code>TemplateS3Uri</code> or the <code>TemplateBody</code> parameter, but not both. If you provide both AWS Config uses the <code>TemplateS3Uri</code> parameter and ignores the <code>TemplateBody</code> parameter.</p> <p>AWS Config sets the state of a conformance pack to CREATE_IN_PROGRESS and UPDATE_IN_PROGRESS until the confomance pack is created or updated. You cannot update a conformance pack while it is in this state.</p> <p>You can create 6 conformance packs with 25 AWS Config rules in each pack.</p> </note>
  ## 
  let valid = call_21627027.validator(path, query, header, formData, body, _)
  let scheme = call_21627027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627027.makeUrl(scheme.get, call_21627027.host, call_21627027.base,
                               call_21627027.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627027, uri, valid, _)

proc call*(call_21627028: Call_PutOrganizationConformancePack_21627015;
          body: JsonNode): Recallable =
  ## putOrganizationConformancePack
  ## <p>Deploys conformance packs across member accounts in an AWS Organization.</p> <p>This API enables organization service access for <code>config-multiaccountsetup.amazonaws.com</code> through the <code>EnableAWSServiceAccess</code> action and creates a service linked role <code>AWSServiceRoleForConfigMultiAccountSetup</code> in the master account of your organization. The service linked role is created only when the role does not exist in the master account. AWS Config verifies the existence of role with GetRole action.</p> <note> <p>You must specify either the <code>TemplateS3Uri</code> or the <code>TemplateBody</code> parameter, but not both. If you provide both AWS Config uses the <code>TemplateS3Uri</code> parameter and ignores the <code>TemplateBody</code> parameter.</p> <p>AWS Config sets the state of a conformance pack to CREATE_IN_PROGRESS and UPDATE_IN_PROGRESS until the confomance pack is created or updated. You cannot update a conformance pack while it is in this state.</p> <p>You can create 6 conformance packs with 25 AWS Config rules in each pack.</p> </note>
  ##   body: JObject (required)
  var body_21627029 = newJObject()
  if body != nil:
    body_21627029 = body
  result = call_21627028.call(nil, nil, nil, nil, body_21627029)

var putOrganizationConformancePack* = Call_PutOrganizationConformancePack_21627015(
    name: "putOrganizationConformancePack", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutOrganizationConformancePack",
    validator: validate_PutOrganizationConformancePack_21627016, base: "/",
    makeUrl: url_PutOrganizationConformancePack_21627017,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRemediationConfigurations_21627030 = ref object of OpenApiRestCall_21625435
proc url_PutRemediationConfigurations_21627032(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutRemediationConfigurations_21627031(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Adds or updates the remediation configuration with a specific AWS Config rule with the selected target or action. The API creates the <code>RemediationConfiguration</code> object for the AWS Config rule. The AWS Config rule must already exist for you to add a remediation configuration. The target (SSM document) must exist and have permissions to use the target. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627033 = header.getOrDefault("X-Amz-Date")
  valid_21627033 = validateParameter(valid_21627033, JString, required = false,
                                   default = nil)
  if valid_21627033 != nil:
    section.add "X-Amz-Date", valid_21627033
  var valid_21627034 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627034 = validateParameter(valid_21627034, JString, required = false,
                                   default = nil)
  if valid_21627034 != nil:
    section.add "X-Amz-Security-Token", valid_21627034
  var valid_21627035 = header.getOrDefault("X-Amz-Target")
  valid_21627035 = validateParameter(valid_21627035, JString, required = true, default = newJString(
      "StarlingDoveService.PutRemediationConfigurations"))
  if valid_21627035 != nil:
    section.add "X-Amz-Target", valid_21627035
  var valid_21627036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627036 = validateParameter(valid_21627036, JString, required = false,
                                   default = nil)
  if valid_21627036 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627036
  var valid_21627037 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627037 = validateParameter(valid_21627037, JString, required = false,
                                   default = nil)
  if valid_21627037 != nil:
    section.add "X-Amz-Algorithm", valid_21627037
  var valid_21627038 = header.getOrDefault("X-Amz-Signature")
  valid_21627038 = validateParameter(valid_21627038, JString, required = false,
                                   default = nil)
  if valid_21627038 != nil:
    section.add "X-Amz-Signature", valid_21627038
  var valid_21627039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627039 = validateParameter(valid_21627039, JString, required = false,
                                   default = nil)
  if valid_21627039 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627039
  var valid_21627040 = header.getOrDefault("X-Amz-Credential")
  valid_21627040 = validateParameter(valid_21627040, JString, required = false,
                                   default = nil)
  if valid_21627040 != nil:
    section.add "X-Amz-Credential", valid_21627040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627042: Call_PutRemediationConfigurations_21627030;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds or updates the remediation configuration with a specific AWS Config rule with the selected target or action. The API creates the <code>RemediationConfiguration</code> object for the AWS Config rule. The AWS Config rule must already exist for you to add a remediation configuration. The target (SSM document) must exist and have permissions to use the target. 
  ## 
  let valid = call_21627042.validator(path, query, header, formData, body, _)
  let scheme = call_21627042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627042.makeUrl(scheme.get, call_21627042.host, call_21627042.base,
                               call_21627042.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627042, uri, valid, _)

proc call*(call_21627043: Call_PutRemediationConfigurations_21627030;
          body: JsonNode): Recallable =
  ## putRemediationConfigurations
  ## Adds or updates the remediation configuration with a specific AWS Config rule with the selected target or action. The API creates the <code>RemediationConfiguration</code> object for the AWS Config rule. The AWS Config rule must already exist for you to add a remediation configuration. The target (SSM document) must exist and have permissions to use the target. 
  ##   body: JObject (required)
  var body_21627044 = newJObject()
  if body != nil:
    body_21627044 = body
  result = call_21627043.call(nil, nil, nil, nil, body_21627044)

var putRemediationConfigurations* = Call_PutRemediationConfigurations_21627030(
    name: "putRemediationConfigurations", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutRemediationConfigurations",
    validator: validate_PutRemediationConfigurations_21627031, base: "/",
    makeUrl: url_PutRemediationConfigurations_21627032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRemediationExceptions_21627045 = ref object of OpenApiRestCall_21625435
proc url_PutRemediationExceptions_21627047(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutRemediationExceptions_21627046(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## A remediation exception is when a specific resource is no longer considered for auto-remediation. This API adds a new exception or updates an exisiting exception for a specific resource with a specific AWS Config rule. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627048 = header.getOrDefault("X-Amz-Date")
  valid_21627048 = validateParameter(valid_21627048, JString, required = false,
                                   default = nil)
  if valid_21627048 != nil:
    section.add "X-Amz-Date", valid_21627048
  var valid_21627049 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627049 = validateParameter(valid_21627049, JString, required = false,
                                   default = nil)
  if valid_21627049 != nil:
    section.add "X-Amz-Security-Token", valid_21627049
  var valid_21627050 = header.getOrDefault("X-Amz-Target")
  valid_21627050 = validateParameter(valid_21627050, JString, required = true, default = newJString(
      "StarlingDoveService.PutRemediationExceptions"))
  if valid_21627050 != nil:
    section.add "X-Amz-Target", valid_21627050
  var valid_21627051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627051 = validateParameter(valid_21627051, JString, required = false,
                                   default = nil)
  if valid_21627051 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627051
  var valid_21627052 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627052 = validateParameter(valid_21627052, JString, required = false,
                                   default = nil)
  if valid_21627052 != nil:
    section.add "X-Amz-Algorithm", valid_21627052
  var valid_21627053 = header.getOrDefault("X-Amz-Signature")
  valid_21627053 = validateParameter(valid_21627053, JString, required = false,
                                   default = nil)
  if valid_21627053 != nil:
    section.add "X-Amz-Signature", valid_21627053
  var valid_21627054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627054 = validateParameter(valid_21627054, JString, required = false,
                                   default = nil)
  if valid_21627054 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627054
  var valid_21627055 = header.getOrDefault("X-Amz-Credential")
  valid_21627055 = validateParameter(valid_21627055, JString, required = false,
                                   default = nil)
  if valid_21627055 != nil:
    section.add "X-Amz-Credential", valid_21627055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627057: Call_PutRemediationExceptions_21627045;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## A remediation exception is when a specific resource is no longer considered for auto-remediation. This API adds a new exception or updates an exisiting exception for a specific resource with a specific AWS Config rule. 
  ## 
  let valid = call_21627057.validator(path, query, header, formData, body, _)
  let scheme = call_21627057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627057.makeUrl(scheme.get, call_21627057.host, call_21627057.base,
                               call_21627057.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627057, uri, valid, _)

proc call*(call_21627058: Call_PutRemediationExceptions_21627045; body: JsonNode): Recallable =
  ## putRemediationExceptions
  ## A remediation exception is when a specific resource is no longer considered for auto-remediation. This API adds a new exception or updates an exisiting exception for a specific resource with a specific AWS Config rule. 
  ##   body: JObject (required)
  var body_21627059 = newJObject()
  if body != nil:
    body_21627059 = body
  result = call_21627058.call(nil, nil, nil, nil, body_21627059)

var putRemediationExceptions* = Call_PutRemediationExceptions_21627045(
    name: "putRemediationExceptions", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutRemediationExceptions",
    validator: validate_PutRemediationExceptions_21627046, base: "/",
    makeUrl: url_PutRemediationExceptions_21627047,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourceConfig_21627060 = ref object of OpenApiRestCall_21625435
proc url_PutResourceConfig_21627062(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutResourceConfig_21627061(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Records the configuration state for the resource provided in the request. The configuration state of a resource is represented in AWS Config as Configuration Items. Once this API records the configuration item, you can retrieve the list of configuration items for the custom resource type using existing AWS Config APIs. </p> <note> <p>The custom resource type must be registered with AWS CloudFormation. This API accepts the configuration item registered with AWS CloudFormation.</p> <p>When you call this API, AWS Config only stores configuration state of the resource provided in the request. This API does not change or remediate the configuration of the resource. </p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627063 = header.getOrDefault("X-Amz-Date")
  valid_21627063 = validateParameter(valid_21627063, JString, required = false,
                                   default = nil)
  if valid_21627063 != nil:
    section.add "X-Amz-Date", valid_21627063
  var valid_21627064 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627064 = validateParameter(valid_21627064, JString, required = false,
                                   default = nil)
  if valid_21627064 != nil:
    section.add "X-Amz-Security-Token", valid_21627064
  var valid_21627065 = header.getOrDefault("X-Amz-Target")
  valid_21627065 = validateParameter(valid_21627065, JString, required = true, default = newJString(
      "StarlingDoveService.PutResourceConfig"))
  if valid_21627065 != nil:
    section.add "X-Amz-Target", valid_21627065
  var valid_21627066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627066 = validateParameter(valid_21627066, JString, required = false,
                                   default = nil)
  if valid_21627066 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627066
  var valid_21627067 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627067 = validateParameter(valid_21627067, JString, required = false,
                                   default = nil)
  if valid_21627067 != nil:
    section.add "X-Amz-Algorithm", valid_21627067
  var valid_21627068 = header.getOrDefault("X-Amz-Signature")
  valid_21627068 = validateParameter(valid_21627068, JString, required = false,
                                   default = nil)
  if valid_21627068 != nil:
    section.add "X-Amz-Signature", valid_21627068
  var valid_21627069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627069 = validateParameter(valid_21627069, JString, required = false,
                                   default = nil)
  if valid_21627069 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627069
  var valid_21627070 = header.getOrDefault("X-Amz-Credential")
  valid_21627070 = validateParameter(valid_21627070, JString, required = false,
                                   default = nil)
  if valid_21627070 != nil:
    section.add "X-Amz-Credential", valid_21627070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627072: Call_PutResourceConfig_21627060; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Records the configuration state for the resource provided in the request. The configuration state of a resource is represented in AWS Config as Configuration Items. Once this API records the configuration item, you can retrieve the list of configuration items for the custom resource type using existing AWS Config APIs. </p> <note> <p>The custom resource type must be registered with AWS CloudFormation. This API accepts the configuration item registered with AWS CloudFormation.</p> <p>When you call this API, AWS Config only stores configuration state of the resource provided in the request. This API does not change or remediate the configuration of the resource. </p> </note>
  ## 
  let valid = call_21627072.validator(path, query, header, formData, body, _)
  let scheme = call_21627072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627072.makeUrl(scheme.get, call_21627072.host, call_21627072.base,
                               call_21627072.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627072, uri, valid, _)

proc call*(call_21627073: Call_PutResourceConfig_21627060; body: JsonNode): Recallable =
  ## putResourceConfig
  ## <p>Records the configuration state for the resource provided in the request. The configuration state of a resource is represented in AWS Config as Configuration Items. Once this API records the configuration item, you can retrieve the list of configuration items for the custom resource type using existing AWS Config APIs. </p> <note> <p>The custom resource type must be registered with AWS CloudFormation. This API accepts the configuration item registered with AWS CloudFormation.</p> <p>When you call this API, AWS Config only stores configuration state of the resource provided in the request. This API does not change or remediate the configuration of the resource. </p> </note>
  ##   body: JObject (required)
  var body_21627074 = newJObject()
  if body != nil:
    body_21627074 = body
  result = call_21627073.call(nil, nil, nil, nil, body_21627074)

var putResourceConfig* = Call_PutResourceConfig_21627060(name: "putResourceConfig",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutResourceConfig",
    validator: validate_PutResourceConfig_21627061, base: "/",
    makeUrl: url_PutResourceConfig_21627062, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRetentionConfiguration_21627075 = ref object of OpenApiRestCall_21625435
proc url_PutRetentionConfiguration_21627077(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutRetentionConfiguration_21627076(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates and updates the retention configuration with details about retention period (number of days) that AWS Config stores your historical information. The API creates the <code>RetentionConfiguration</code> object and names the object as <b>default</b>. When you have a <code>RetentionConfiguration</code> object named <b>default</b>, calling the API modifies the default object. </p> <note> <p>Currently, AWS Config supports only one retention configuration per region in your account.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627078 = header.getOrDefault("X-Amz-Date")
  valid_21627078 = validateParameter(valid_21627078, JString, required = false,
                                   default = nil)
  if valid_21627078 != nil:
    section.add "X-Amz-Date", valid_21627078
  var valid_21627079 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627079 = validateParameter(valid_21627079, JString, required = false,
                                   default = nil)
  if valid_21627079 != nil:
    section.add "X-Amz-Security-Token", valid_21627079
  var valid_21627080 = header.getOrDefault("X-Amz-Target")
  valid_21627080 = validateParameter(valid_21627080, JString, required = true, default = newJString(
      "StarlingDoveService.PutRetentionConfiguration"))
  if valid_21627080 != nil:
    section.add "X-Amz-Target", valid_21627080
  var valid_21627081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627081 = validateParameter(valid_21627081, JString, required = false,
                                   default = nil)
  if valid_21627081 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627081
  var valid_21627082 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627082 = validateParameter(valid_21627082, JString, required = false,
                                   default = nil)
  if valid_21627082 != nil:
    section.add "X-Amz-Algorithm", valid_21627082
  var valid_21627083 = header.getOrDefault("X-Amz-Signature")
  valid_21627083 = validateParameter(valid_21627083, JString, required = false,
                                   default = nil)
  if valid_21627083 != nil:
    section.add "X-Amz-Signature", valid_21627083
  var valid_21627084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627084 = validateParameter(valid_21627084, JString, required = false,
                                   default = nil)
  if valid_21627084 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627084
  var valid_21627085 = header.getOrDefault("X-Amz-Credential")
  valid_21627085 = validateParameter(valid_21627085, JString, required = false,
                                   default = nil)
  if valid_21627085 != nil:
    section.add "X-Amz-Credential", valid_21627085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627087: Call_PutRetentionConfiguration_21627075;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates and updates the retention configuration with details about retention period (number of days) that AWS Config stores your historical information. The API creates the <code>RetentionConfiguration</code> object and names the object as <b>default</b>. When you have a <code>RetentionConfiguration</code> object named <b>default</b>, calling the API modifies the default object. </p> <note> <p>Currently, AWS Config supports only one retention configuration per region in your account.</p> </note>
  ## 
  let valid = call_21627087.validator(path, query, header, formData, body, _)
  let scheme = call_21627087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627087.makeUrl(scheme.get, call_21627087.host, call_21627087.base,
                               call_21627087.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627087, uri, valid, _)

proc call*(call_21627088: Call_PutRetentionConfiguration_21627075; body: JsonNode): Recallable =
  ## putRetentionConfiguration
  ## <p>Creates and updates the retention configuration with details about retention period (number of days) that AWS Config stores your historical information. The API creates the <code>RetentionConfiguration</code> object and names the object as <b>default</b>. When you have a <code>RetentionConfiguration</code> object named <b>default</b>, calling the API modifies the default object. </p> <note> <p>Currently, AWS Config supports only one retention configuration per region in your account.</p> </note>
  ##   body: JObject (required)
  var body_21627089 = newJObject()
  if body != nil:
    body_21627089 = body
  result = call_21627088.call(nil, nil, nil, nil, body_21627089)

var putRetentionConfiguration* = Call_PutRetentionConfiguration_21627075(
    name: "putRetentionConfiguration", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutRetentionConfiguration",
    validator: validate_PutRetentionConfiguration_21627076, base: "/",
    makeUrl: url_PutRetentionConfiguration_21627077,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SelectResourceConfig_21627090 = ref object of OpenApiRestCall_21625435
proc url_SelectResourceConfig_21627092(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SelectResourceConfig_21627091(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Accepts a structured query language (SQL) <code>SELECT</code> command, performs the corresponding search, and returns resource configurations matching the properties.</p> <p>For more information about query components, see the <a href="https://docs.aws.amazon.com/config/latest/developerguide/query-components.html"> <b>Query Components</b> </a> section in the AWS Config Developer Guide.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627093 = header.getOrDefault("X-Amz-Date")
  valid_21627093 = validateParameter(valid_21627093, JString, required = false,
                                   default = nil)
  if valid_21627093 != nil:
    section.add "X-Amz-Date", valid_21627093
  var valid_21627094 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627094 = validateParameter(valid_21627094, JString, required = false,
                                   default = nil)
  if valid_21627094 != nil:
    section.add "X-Amz-Security-Token", valid_21627094
  var valid_21627095 = header.getOrDefault("X-Amz-Target")
  valid_21627095 = validateParameter(valid_21627095, JString, required = true, default = newJString(
      "StarlingDoveService.SelectResourceConfig"))
  if valid_21627095 != nil:
    section.add "X-Amz-Target", valid_21627095
  var valid_21627096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627096 = validateParameter(valid_21627096, JString, required = false,
                                   default = nil)
  if valid_21627096 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627096
  var valid_21627097 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627097 = validateParameter(valid_21627097, JString, required = false,
                                   default = nil)
  if valid_21627097 != nil:
    section.add "X-Amz-Algorithm", valid_21627097
  var valid_21627098 = header.getOrDefault("X-Amz-Signature")
  valid_21627098 = validateParameter(valid_21627098, JString, required = false,
                                   default = nil)
  if valid_21627098 != nil:
    section.add "X-Amz-Signature", valid_21627098
  var valid_21627099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627099 = validateParameter(valid_21627099, JString, required = false,
                                   default = nil)
  if valid_21627099 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627099
  var valid_21627100 = header.getOrDefault("X-Amz-Credential")
  valid_21627100 = validateParameter(valid_21627100, JString, required = false,
                                   default = nil)
  if valid_21627100 != nil:
    section.add "X-Amz-Credential", valid_21627100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627102: Call_SelectResourceConfig_21627090; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Accepts a structured query language (SQL) <code>SELECT</code> command, performs the corresponding search, and returns resource configurations matching the properties.</p> <p>For more information about query components, see the <a href="https://docs.aws.amazon.com/config/latest/developerguide/query-components.html"> <b>Query Components</b> </a> section in the AWS Config Developer Guide.</p>
  ## 
  let valid = call_21627102.validator(path, query, header, formData, body, _)
  let scheme = call_21627102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627102.makeUrl(scheme.get, call_21627102.host, call_21627102.base,
                               call_21627102.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627102, uri, valid, _)

proc call*(call_21627103: Call_SelectResourceConfig_21627090; body: JsonNode): Recallable =
  ## selectResourceConfig
  ## <p>Accepts a structured query language (SQL) <code>SELECT</code> command, performs the corresponding search, and returns resource configurations matching the properties.</p> <p>For more information about query components, see the <a href="https://docs.aws.amazon.com/config/latest/developerguide/query-components.html"> <b>Query Components</b> </a> section in the AWS Config Developer Guide.</p>
  ##   body: JObject (required)
  var body_21627104 = newJObject()
  if body != nil:
    body_21627104 = body
  result = call_21627103.call(nil, nil, nil, nil, body_21627104)

var selectResourceConfig* = Call_SelectResourceConfig_21627090(
    name: "selectResourceConfig", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.SelectResourceConfig",
    validator: validate_SelectResourceConfig_21627091, base: "/",
    makeUrl: url_SelectResourceConfig_21627092,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartConfigRulesEvaluation_21627105 = ref object of OpenApiRestCall_21625435
proc url_StartConfigRulesEvaluation_21627107(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartConfigRulesEvaluation_21627106(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Runs an on-demand evaluation for the specified AWS Config rules against the last known configuration state of the resources. Use <code>StartConfigRulesEvaluation</code> when you want to test that a rule you updated is working as expected. <code>StartConfigRulesEvaluation</code> does not re-record the latest configuration state for your resources. It re-runs an evaluation against the last known state of your resources. </p> <p>You can specify up to 25 AWS Config rules per request. </p> <p>An existing <code>StartConfigRulesEvaluation</code> call for the specified rules must complete before you can call the API again. If you chose to have AWS Config stream to an Amazon SNS topic, you will receive a <code>ConfigRuleEvaluationStarted</code> notification when the evaluation starts.</p> <note> <p>You don't need to call the <code>StartConfigRulesEvaluation</code> API to run an evaluation for a new rule. When you create a rule, AWS Config evaluates your resources against the rule automatically. </p> </note> <p>The <code>StartConfigRulesEvaluation</code> API is useful if you want to run on-demand evaluations, such as the following example:</p> <ol> <li> <p>You have a custom rule that evaluates your IAM resources every 24 hours.</p> </li> <li> <p>You update your Lambda function to add additional conditions to your rule.</p> </li> <li> <p>Instead of waiting for the next periodic evaluation, you call the <code>StartConfigRulesEvaluation</code> API.</p> </li> <li> <p>AWS Config invokes your Lambda function and evaluates your IAM resources.</p> </li> <li> <p>Your custom rule will still run periodic evaluations every 24 hours.</p> </li> </ol>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627108 = header.getOrDefault("X-Amz-Date")
  valid_21627108 = validateParameter(valid_21627108, JString, required = false,
                                   default = nil)
  if valid_21627108 != nil:
    section.add "X-Amz-Date", valid_21627108
  var valid_21627109 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627109 = validateParameter(valid_21627109, JString, required = false,
                                   default = nil)
  if valid_21627109 != nil:
    section.add "X-Amz-Security-Token", valid_21627109
  var valid_21627110 = header.getOrDefault("X-Amz-Target")
  valid_21627110 = validateParameter(valid_21627110, JString, required = true, default = newJString(
      "StarlingDoveService.StartConfigRulesEvaluation"))
  if valid_21627110 != nil:
    section.add "X-Amz-Target", valid_21627110
  var valid_21627111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627111 = validateParameter(valid_21627111, JString, required = false,
                                   default = nil)
  if valid_21627111 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627111
  var valid_21627112 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627112 = validateParameter(valid_21627112, JString, required = false,
                                   default = nil)
  if valid_21627112 != nil:
    section.add "X-Amz-Algorithm", valid_21627112
  var valid_21627113 = header.getOrDefault("X-Amz-Signature")
  valid_21627113 = validateParameter(valid_21627113, JString, required = false,
                                   default = nil)
  if valid_21627113 != nil:
    section.add "X-Amz-Signature", valid_21627113
  var valid_21627114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627114 = validateParameter(valid_21627114, JString, required = false,
                                   default = nil)
  if valid_21627114 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627114
  var valid_21627115 = header.getOrDefault("X-Amz-Credential")
  valid_21627115 = validateParameter(valid_21627115, JString, required = false,
                                   default = nil)
  if valid_21627115 != nil:
    section.add "X-Amz-Credential", valid_21627115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627117: Call_StartConfigRulesEvaluation_21627105;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Runs an on-demand evaluation for the specified AWS Config rules against the last known configuration state of the resources. Use <code>StartConfigRulesEvaluation</code> when you want to test that a rule you updated is working as expected. <code>StartConfigRulesEvaluation</code> does not re-record the latest configuration state for your resources. It re-runs an evaluation against the last known state of your resources. </p> <p>You can specify up to 25 AWS Config rules per request. </p> <p>An existing <code>StartConfigRulesEvaluation</code> call for the specified rules must complete before you can call the API again. If you chose to have AWS Config stream to an Amazon SNS topic, you will receive a <code>ConfigRuleEvaluationStarted</code> notification when the evaluation starts.</p> <note> <p>You don't need to call the <code>StartConfigRulesEvaluation</code> API to run an evaluation for a new rule. When you create a rule, AWS Config evaluates your resources against the rule automatically. </p> </note> <p>The <code>StartConfigRulesEvaluation</code> API is useful if you want to run on-demand evaluations, such as the following example:</p> <ol> <li> <p>You have a custom rule that evaluates your IAM resources every 24 hours.</p> </li> <li> <p>You update your Lambda function to add additional conditions to your rule.</p> </li> <li> <p>Instead of waiting for the next periodic evaluation, you call the <code>StartConfigRulesEvaluation</code> API.</p> </li> <li> <p>AWS Config invokes your Lambda function and evaluates your IAM resources.</p> </li> <li> <p>Your custom rule will still run periodic evaluations every 24 hours.</p> </li> </ol>
  ## 
  let valid = call_21627117.validator(path, query, header, formData, body, _)
  let scheme = call_21627117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627117.makeUrl(scheme.get, call_21627117.host, call_21627117.base,
                               call_21627117.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627117, uri, valid, _)

proc call*(call_21627118: Call_StartConfigRulesEvaluation_21627105; body: JsonNode): Recallable =
  ## startConfigRulesEvaluation
  ## <p>Runs an on-demand evaluation for the specified AWS Config rules against the last known configuration state of the resources. Use <code>StartConfigRulesEvaluation</code> when you want to test that a rule you updated is working as expected. <code>StartConfigRulesEvaluation</code> does not re-record the latest configuration state for your resources. It re-runs an evaluation against the last known state of your resources. </p> <p>You can specify up to 25 AWS Config rules per request. </p> <p>An existing <code>StartConfigRulesEvaluation</code> call for the specified rules must complete before you can call the API again. If you chose to have AWS Config stream to an Amazon SNS topic, you will receive a <code>ConfigRuleEvaluationStarted</code> notification when the evaluation starts.</p> <note> <p>You don't need to call the <code>StartConfigRulesEvaluation</code> API to run an evaluation for a new rule. When you create a rule, AWS Config evaluates your resources against the rule automatically. </p> </note> <p>The <code>StartConfigRulesEvaluation</code> API is useful if you want to run on-demand evaluations, such as the following example:</p> <ol> <li> <p>You have a custom rule that evaluates your IAM resources every 24 hours.</p> </li> <li> <p>You update your Lambda function to add additional conditions to your rule.</p> </li> <li> <p>Instead of waiting for the next periodic evaluation, you call the <code>StartConfigRulesEvaluation</code> API.</p> </li> <li> <p>AWS Config invokes your Lambda function and evaluates your IAM resources.</p> </li> <li> <p>Your custom rule will still run periodic evaluations every 24 hours.</p> </li> </ol>
  ##   body: JObject (required)
  var body_21627119 = newJObject()
  if body != nil:
    body_21627119 = body
  result = call_21627118.call(nil, nil, nil, nil, body_21627119)

var startConfigRulesEvaluation* = Call_StartConfigRulesEvaluation_21627105(
    name: "startConfigRulesEvaluation", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.StartConfigRulesEvaluation",
    validator: validate_StartConfigRulesEvaluation_21627106, base: "/",
    makeUrl: url_StartConfigRulesEvaluation_21627107,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartConfigurationRecorder_21627120 = ref object of OpenApiRestCall_21625435
proc url_StartConfigurationRecorder_21627122(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartConfigurationRecorder_21627121(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Starts recording configurations of the AWS resources you have selected to record in your AWS account.</p> <p>You must have created at least one delivery channel to successfully start the configuration recorder.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627123 = header.getOrDefault("X-Amz-Date")
  valid_21627123 = validateParameter(valid_21627123, JString, required = false,
                                   default = nil)
  if valid_21627123 != nil:
    section.add "X-Amz-Date", valid_21627123
  var valid_21627124 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627124 = validateParameter(valid_21627124, JString, required = false,
                                   default = nil)
  if valid_21627124 != nil:
    section.add "X-Amz-Security-Token", valid_21627124
  var valid_21627125 = header.getOrDefault("X-Amz-Target")
  valid_21627125 = validateParameter(valid_21627125, JString, required = true, default = newJString(
      "StarlingDoveService.StartConfigurationRecorder"))
  if valid_21627125 != nil:
    section.add "X-Amz-Target", valid_21627125
  var valid_21627126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627126 = validateParameter(valid_21627126, JString, required = false,
                                   default = nil)
  if valid_21627126 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627126
  var valid_21627127 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627127 = validateParameter(valid_21627127, JString, required = false,
                                   default = nil)
  if valid_21627127 != nil:
    section.add "X-Amz-Algorithm", valid_21627127
  var valid_21627128 = header.getOrDefault("X-Amz-Signature")
  valid_21627128 = validateParameter(valid_21627128, JString, required = false,
                                   default = nil)
  if valid_21627128 != nil:
    section.add "X-Amz-Signature", valid_21627128
  var valid_21627129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627129 = validateParameter(valid_21627129, JString, required = false,
                                   default = nil)
  if valid_21627129 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627129
  var valid_21627130 = header.getOrDefault("X-Amz-Credential")
  valid_21627130 = validateParameter(valid_21627130, JString, required = false,
                                   default = nil)
  if valid_21627130 != nil:
    section.add "X-Amz-Credential", valid_21627130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627132: Call_StartConfigurationRecorder_21627120;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts recording configurations of the AWS resources you have selected to record in your AWS account.</p> <p>You must have created at least one delivery channel to successfully start the configuration recorder.</p>
  ## 
  let valid = call_21627132.validator(path, query, header, formData, body, _)
  let scheme = call_21627132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627132.makeUrl(scheme.get, call_21627132.host, call_21627132.base,
                               call_21627132.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627132, uri, valid, _)

proc call*(call_21627133: Call_StartConfigurationRecorder_21627120; body: JsonNode): Recallable =
  ## startConfigurationRecorder
  ## <p>Starts recording configurations of the AWS resources you have selected to record in your AWS account.</p> <p>You must have created at least one delivery channel to successfully start the configuration recorder.</p>
  ##   body: JObject (required)
  var body_21627134 = newJObject()
  if body != nil:
    body_21627134 = body
  result = call_21627133.call(nil, nil, nil, nil, body_21627134)

var startConfigurationRecorder* = Call_StartConfigurationRecorder_21627120(
    name: "startConfigurationRecorder", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.StartConfigurationRecorder",
    validator: validate_StartConfigurationRecorder_21627121, base: "/",
    makeUrl: url_StartConfigurationRecorder_21627122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartRemediationExecution_21627135 = ref object of OpenApiRestCall_21625435
proc url_StartRemediationExecution_21627137(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartRemediationExecution_21627136(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Runs an on-demand remediation for the specified AWS Config rules against the last known remediation configuration. It runs an execution against the current state of your resources. Remediation execution is asynchronous.</p> <p>You can specify up to 100 resource keys per request. An existing StartRemediationExecution call for the specified resource keys must complete before you can call the API again.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627138 = header.getOrDefault("X-Amz-Date")
  valid_21627138 = validateParameter(valid_21627138, JString, required = false,
                                   default = nil)
  if valid_21627138 != nil:
    section.add "X-Amz-Date", valid_21627138
  var valid_21627139 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627139 = validateParameter(valid_21627139, JString, required = false,
                                   default = nil)
  if valid_21627139 != nil:
    section.add "X-Amz-Security-Token", valid_21627139
  var valid_21627140 = header.getOrDefault("X-Amz-Target")
  valid_21627140 = validateParameter(valid_21627140, JString, required = true, default = newJString(
      "StarlingDoveService.StartRemediationExecution"))
  if valid_21627140 != nil:
    section.add "X-Amz-Target", valid_21627140
  var valid_21627141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627141 = validateParameter(valid_21627141, JString, required = false,
                                   default = nil)
  if valid_21627141 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627141
  var valid_21627142 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627142 = validateParameter(valid_21627142, JString, required = false,
                                   default = nil)
  if valid_21627142 != nil:
    section.add "X-Amz-Algorithm", valid_21627142
  var valid_21627143 = header.getOrDefault("X-Amz-Signature")
  valid_21627143 = validateParameter(valid_21627143, JString, required = false,
                                   default = nil)
  if valid_21627143 != nil:
    section.add "X-Amz-Signature", valid_21627143
  var valid_21627144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627144 = validateParameter(valid_21627144, JString, required = false,
                                   default = nil)
  if valid_21627144 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627144
  var valid_21627145 = header.getOrDefault("X-Amz-Credential")
  valid_21627145 = validateParameter(valid_21627145, JString, required = false,
                                   default = nil)
  if valid_21627145 != nil:
    section.add "X-Amz-Credential", valid_21627145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627147: Call_StartRemediationExecution_21627135;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Runs an on-demand remediation for the specified AWS Config rules against the last known remediation configuration. It runs an execution against the current state of your resources. Remediation execution is asynchronous.</p> <p>You can specify up to 100 resource keys per request. An existing StartRemediationExecution call for the specified resource keys must complete before you can call the API again.</p>
  ## 
  let valid = call_21627147.validator(path, query, header, formData, body, _)
  let scheme = call_21627147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627147.makeUrl(scheme.get, call_21627147.host, call_21627147.base,
                               call_21627147.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627147, uri, valid, _)

proc call*(call_21627148: Call_StartRemediationExecution_21627135; body: JsonNode): Recallable =
  ## startRemediationExecution
  ## <p>Runs an on-demand remediation for the specified AWS Config rules against the last known remediation configuration. It runs an execution against the current state of your resources. Remediation execution is asynchronous.</p> <p>You can specify up to 100 resource keys per request. An existing StartRemediationExecution call for the specified resource keys must complete before you can call the API again.</p>
  ##   body: JObject (required)
  var body_21627149 = newJObject()
  if body != nil:
    body_21627149 = body
  result = call_21627148.call(nil, nil, nil, nil, body_21627149)

var startRemediationExecution* = Call_StartRemediationExecution_21627135(
    name: "startRemediationExecution", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.StartRemediationExecution",
    validator: validate_StartRemediationExecution_21627136, base: "/",
    makeUrl: url_StartRemediationExecution_21627137,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopConfigurationRecorder_21627150 = ref object of OpenApiRestCall_21625435
proc url_StopConfigurationRecorder_21627152(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopConfigurationRecorder_21627151(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Stops recording configurations of the AWS resources you have selected to record in your AWS account.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627153 = header.getOrDefault("X-Amz-Date")
  valid_21627153 = validateParameter(valid_21627153, JString, required = false,
                                   default = nil)
  if valid_21627153 != nil:
    section.add "X-Amz-Date", valid_21627153
  var valid_21627154 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627154 = validateParameter(valid_21627154, JString, required = false,
                                   default = nil)
  if valid_21627154 != nil:
    section.add "X-Amz-Security-Token", valid_21627154
  var valid_21627155 = header.getOrDefault("X-Amz-Target")
  valid_21627155 = validateParameter(valid_21627155, JString, required = true, default = newJString(
      "StarlingDoveService.StopConfigurationRecorder"))
  if valid_21627155 != nil:
    section.add "X-Amz-Target", valid_21627155
  var valid_21627156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627156 = validateParameter(valid_21627156, JString, required = false,
                                   default = nil)
  if valid_21627156 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627156
  var valid_21627157 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627157 = validateParameter(valid_21627157, JString, required = false,
                                   default = nil)
  if valid_21627157 != nil:
    section.add "X-Amz-Algorithm", valid_21627157
  var valid_21627158 = header.getOrDefault("X-Amz-Signature")
  valid_21627158 = validateParameter(valid_21627158, JString, required = false,
                                   default = nil)
  if valid_21627158 != nil:
    section.add "X-Amz-Signature", valid_21627158
  var valid_21627159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627159 = validateParameter(valid_21627159, JString, required = false,
                                   default = nil)
  if valid_21627159 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627159
  var valid_21627160 = header.getOrDefault("X-Amz-Credential")
  valid_21627160 = validateParameter(valid_21627160, JString, required = false,
                                   default = nil)
  if valid_21627160 != nil:
    section.add "X-Amz-Credential", valid_21627160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627162: Call_StopConfigurationRecorder_21627150;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops recording configurations of the AWS resources you have selected to record in your AWS account.
  ## 
  let valid = call_21627162.validator(path, query, header, formData, body, _)
  let scheme = call_21627162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627162.makeUrl(scheme.get, call_21627162.host, call_21627162.base,
                               call_21627162.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627162, uri, valid, _)

proc call*(call_21627163: Call_StopConfigurationRecorder_21627150; body: JsonNode): Recallable =
  ## stopConfigurationRecorder
  ## Stops recording configurations of the AWS resources you have selected to record in your AWS account.
  ##   body: JObject (required)
  var body_21627164 = newJObject()
  if body != nil:
    body_21627164 = body
  result = call_21627163.call(nil, nil, nil, nil, body_21627164)

var stopConfigurationRecorder* = Call_StopConfigurationRecorder_21627150(
    name: "stopConfigurationRecorder", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.StopConfigurationRecorder",
    validator: validate_StopConfigurationRecorder_21627151, base: "/",
    makeUrl: url_StopConfigurationRecorder_21627152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21627165 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21627167(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_21627166(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627168 = header.getOrDefault("X-Amz-Date")
  valid_21627168 = validateParameter(valid_21627168, JString, required = false,
                                   default = nil)
  if valid_21627168 != nil:
    section.add "X-Amz-Date", valid_21627168
  var valid_21627169 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627169 = validateParameter(valid_21627169, JString, required = false,
                                   default = nil)
  if valid_21627169 != nil:
    section.add "X-Amz-Security-Token", valid_21627169
  var valid_21627170 = header.getOrDefault("X-Amz-Target")
  valid_21627170 = validateParameter(valid_21627170, JString, required = true, default = newJString(
      "StarlingDoveService.TagResource"))
  if valid_21627170 != nil:
    section.add "X-Amz-Target", valid_21627170
  var valid_21627171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627171 = validateParameter(valid_21627171, JString, required = false,
                                   default = nil)
  if valid_21627171 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627171
  var valid_21627172 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627172 = validateParameter(valid_21627172, JString, required = false,
                                   default = nil)
  if valid_21627172 != nil:
    section.add "X-Amz-Algorithm", valid_21627172
  var valid_21627173 = header.getOrDefault("X-Amz-Signature")
  valid_21627173 = validateParameter(valid_21627173, JString, required = false,
                                   default = nil)
  if valid_21627173 != nil:
    section.add "X-Amz-Signature", valid_21627173
  var valid_21627174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627174 = validateParameter(valid_21627174, JString, required = false,
                                   default = nil)
  if valid_21627174 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627174
  var valid_21627175 = header.getOrDefault("X-Amz-Credential")
  valid_21627175 = validateParameter(valid_21627175, JString, required = false,
                                   default = nil)
  if valid_21627175 != nil:
    section.add "X-Amz-Credential", valid_21627175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627177: Call_TagResource_21627165; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ## 
  let valid = call_21627177.validator(path, query, header, formData, body, _)
  let scheme = call_21627177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627177.makeUrl(scheme.get, call_21627177.host, call_21627177.base,
                               call_21627177.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627177, uri, valid, _)

proc call*(call_21627178: Call_TagResource_21627165; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ##   body: JObject (required)
  var body_21627179 = newJObject()
  if body != nil:
    body_21627179 = body
  result = call_21627178.call(nil, nil, nil, nil, body_21627179)

var tagResource* = Call_TagResource_21627165(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.TagResource",
    validator: validate_TagResource_21627166, base: "/", makeUrl: url_TagResource_21627167,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21627180 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21627182(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_21627181(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes specified tags from a resource.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627183 = header.getOrDefault("X-Amz-Date")
  valid_21627183 = validateParameter(valid_21627183, JString, required = false,
                                   default = nil)
  if valid_21627183 != nil:
    section.add "X-Amz-Date", valid_21627183
  var valid_21627184 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627184 = validateParameter(valid_21627184, JString, required = false,
                                   default = nil)
  if valid_21627184 != nil:
    section.add "X-Amz-Security-Token", valid_21627184
  var valid_21627185 = header.getOrDefault("X-Amz-Target")
  valid_21627185 = validateParameter(valid_21627185, JString, required = true, default = newJString(
      "StarlingDoveService.UntagResource"))
  if valid_21627185 != nil:
    section.add "X-Amz-Target", valid_21627185
  var valid_21627186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627186 = validateParameter(valid_21627186, JString, required = false,
                                   default = nil)
  if valid_21627186 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627186
  var valid_21627187 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627187 = validateParameter(valid_21627187, JString, required = false,
                                   default = nil)
  if valid_21627187 != nil:
    section.add "X-Amz-Algorithm", valid_21627187
  var valid_21627188 = header.getOrDefault("X-Amz-Signature")
  valid_21627188 = validateParameter(valid_21627188, JString, required = false,
                                   default = nil)
  if valid_21627188 != nil:
    section.add "X-Amz-Signature", valid_21627188
  var valid_21627189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627189 = validateParameter(valid_21627189, JString, required = false,
                                   default = nil)
  if valid_21627189 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627189
  var valid_21627190 = header.getOrDefault("X-Amz-Credential")
  valid_21627190 = validateParameter(valid_21627190, JString, required = false,
                                   default = nil)
  if valid_21627190 != nil:
    section.add "X-Amz-Credential", valid_21627190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21627192: Call_UntagResource_21627180; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_21627192.validator(path, query, header, formData, body, _)
  let scheme = call_21627192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627192.makeUrl(scheme.get, call_21627192.host, call_21627192.base,
                               call_21627192.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627192, uri, valid, _)

proc call*(call_21627193: Call_UntagResource_21627180; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   body: JObject (required)
  var body_21627194 = newJObject()
  if body != nil:
    body_21627194 = body
  result = call_21627193.call(nil, nil, nil, nil, body_21627194)

var untagResource* = Call_UntagResource_21627180(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.UntagResource",
    validator: validate_UntagResource_21627181, base: "/",
    makeUrl: url_UntagResource_21627182, schemes: {Scheme.Https, Scheme.Http})
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}