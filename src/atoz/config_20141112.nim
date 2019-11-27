
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchGetAggregateResourceConfig_599705 = ref object of OpenApiRestCall_599368
proc url_BatchGetAggregateResourceConfig_599707(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetAggregateResourceConfig_599706(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_599819 = header.getOrDefault("X-Amz-Date")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Date", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Security-Token")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Security-Token", valid_599820
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599834 = header.getOrDefault("X-Amz-Target")
  valid_599834 = validateParameter(valid_599834, JString, required = true, default = newJString(
      "StarlingDoveService.BatchGetAggregateResourceConfig"))
  if valid_599834 != nil:
    section.add "X-Amz-Target", valid_599834
  var valid_599835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Content-Sha256", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Algorithm")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Algorithm", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Signature")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Signature", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-SignedHeaders", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Credential")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Credential", valid_599839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599863: Call_BatchGetAggregateResourceConfig_599705;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the current configuration items for resources that are present in your AWS Config aggregator. The operation also returns a list of resources that are not processed in the current request. If there are no unprocessed resources, the operation returns an empty <code>unprocessedResourceIdentifiers</code> list. </p> <note> <ul> <li> <p>The API does not return results for deleted resources.</p> </li> <li> <p> The API does not return tags and relationships.</p> </li> </ul> </note>
  ## 
  let valid = call_599863.validator(path, query, header, formData, body)
  let scheme = call_599863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599863.url(scheme.get, call_599863.host, call_599863.base,
                         call_599863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599863, url, valid)

proc call*(call_599934: Call_BatchGetAggregateResourceConfig_599705; body: JsonNode): Recallable =
  ## batchGetAggregateResourceConfig
  ## <p>Returns the current configuration items for resources that are present in your AWS Config aggregator. The operation also returns a list of resources that are not processed in the current request. If there are no unprocessed resources, the operation returns an empty <code>unprocessedResourceIdentifiers</code> list. </p> <note> <ul> <li> <p>The API does not return results for deleted resources.</p> </li> <li> <p> The API does not return tags and relationships.</p> </li> </ul> </note>
  ##   body: JObject (required)
  var body_599935 = newJObject()
  if body != nil:
    body_599935 = body
  result = call_599934.call(nil, nil, nil, nil, body_599935)

var batchGetAggregateResourceConfig* = Call_BatchGetAggregateResourceConfig_599705(
    name: "batchGetAggregateResourceConfig", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.BatchGetAggregateResourceConfig",
    validator: validate_BatchGetAggregateResourceConfig_599706, base: "/",
    url: url_BatchGetAggregateResourceConfig_599707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetResourceConfig_599974 = ref object of OpenApiRestCall_599368
proc url_BatchGetResourceConfig_599976(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetResourceConfig_599975(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_599977 = header.getOrDefault("X-Amz-Date")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Date", valid_599977
  var valid_599978 = header.getOrDefault("X-Amz-Security-Token")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Security-Token", valid_599978
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599979 = header.getOrDefault("X-Amz-Target")
  valid_599979 = validateParameter(valid_599979, JString, required = true, default = newJString(
      "StarlingDoveService.BatchGetResourceConfig"))
  if valid_599979 != nil:
    section.add "X-Amz-Target", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Content-Sha256", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Algorithm")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Algorithm", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Signature")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Signature", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-SignedHeaders", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Credential")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Credential", valid_599984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599986: Call_BatchGetResourceConfig_599974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the current configuration for one or more requested resources. The operation also returns a list of resources that are not processed in the current request. If there are no unprocessed resources, the operation returns an empty unprocessedResourceKeys list. </p> <note> <ul> <li> <p>The API does not return results for deleted resources.</p> </li> <li> <p> The API does not return any tags for the requested resources. This information is filtered out of the supplementaryConfiguration section of the API response.</p> </li> </ul> </note>
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_BatchGetResourceConfig_599974; body: JsonNode): Recallable =
  ## batchGetResourceConfig
  ## <p>Returns the current configuration for one or more requested resources. The operation also returns a list of resources that are not processed in the current request. If there are no unprocessed resources, the operation returns an empty unprocessedResourceKeys list. </p> <note> <ul> <li> <p>The API does not return results for deleted resources.</p> </li> <li> <p> The API does not return any tags for the requested resources. This information is filtered out of the supplementaryConfiguration section of the API response.</p> </li> </ul> </note>
  ##   body: JObject (required)
  var body_599988 = newJObject()
  if body != nil:
    body_599988 = body
  result = call_599987.call(nil, nil, nil, nil, body_599988)

var batchGetResourceConfig* = Call_BatchGetResourceConfig_599974(
    name: "batchGetResourceConfig", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.BatchGetResourceConfig",
    validator: validate_BatchGetResourceConfig_599975, base: "/",
    url: url_BatchGetResourceConfig_599976, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAggregationAuthorization_599989 = ref object of OpenApiRestCall_599368
proc url_DeleteAggregationAuthorization_599991(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAggregationAuthorization_599990(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_599992 = header.getOrDefault("X-Amz-Date")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Date", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Security-Token")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Security-Token", valid_599993
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599994 = header.getOrDefault("X-Amz-Target")
  valid_599994 = validateParameter(valid_599994, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteAggregationAuthorization"))
  if valid_599994 != nil:
    section.add "X-Amz-Target", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Content-Sha256", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Algorithm")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Algorithm", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Signature")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Signature", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-SignedHeaders", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Credential")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Credential", valid_599999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600001: Call_DeleteAggregationAuthorization_599989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the authorization granted to the specified configuration aggregator account in a specified region.
  ## 
  let valid = call_600001.validator(path, query, header, formData, body)
  let scheme = call_600001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600001.url(scheme.get, call_600001.host, call_600001.base,
                         call_600001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600001, url, valid)

proc call*(call_600002: Call_DeleteAggregationAuthorization_599989; body: JsonNode): Recallable =
  ## deleteAggregationAuthorization
  ## Deletes the authorization granted to the specified configuration aggregator account in a specified region.
  ##   body: JObject (required)
  var body_600003 = newJObject()
  if body != nil:
    body_600003 = body
  result = call_600002.call(nil, nil, nil, nil, body_600003)

var deleteAggregationAuthorization* = Call_DeleteAggregationAuthorization_599989(
    name: "deleteAggregationAuthorization", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteAggregationAuthorization",
    validator: validate_DeleteAggregationAuthorization_599990, base: "/",
    url: url_DeleteAggregationAuthorization_599991,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigRule_600004 = ref object of OpenApiRestCall_599368
proc url_DeleteConfigRule_600006(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConfigRule_600005(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_600007 = header.getOrDefault("X-Amz-Date")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Date", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Security-Token")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Security-Token", valid_600008
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600009 = header.getOrDefault("X-Amz-Target")
  valid_600009 = validateParameter(valid_600009, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteConfigRule"))
  if valid_600009 != nil:
    section.add "X-Amz-Target", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Content-Sha256", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Algorithm")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Algorithm", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Signature")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Signature", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-SignedHeaders", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Credential")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Credential", valid_600014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600016: Call_DeleteConfigRule_600004; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified AWS Config rule and all of its evaluation results.</p> <p>AWS Config sets the state of a rule to <code>DELETING</code> until the deletion is complete. You cannot update a rule while it is in this state. If you make a <code>PutConfigRule</code> or <code>DeleteConfigRule</code> request for the rule, you will receive a <code>ResourceInUseException</code>.</p> <p>You can check the state of a rule by using the <code>DescribeConfigRules</code> request.</p>
  ## 
  let valid = call_600016.validator(path, query, header, formData, body)
  let scheme = call_600016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600016.url(scheme.get, call_600016.host, call_600016.base,
                         call_600016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600016, url, valid)

proc call*(call_600017: Call_DeleteConfigRule_600004; body: JsonNode): Recallable =
  ## deleteConfigRule
  ## <p>Deletes the specified AWS Config rule and all of its evaluation results.</p> <p>AWS Config sets the state of a rule to <code>DELETING</code> until the deletion is complete. You cannot update a rule while it is in this state. If you make a <code>PutConfigRule</code> or <code>DeleteConfigRule</code> request for the rule, you will receive a <code>ResourceInUseException</code>.</p> <p>You can check the state of a rule by using the <code>DescribeConfigRules</code> request.</p>
  ##   body: JObject (required)
  var body_600018 = newJObject()
  if body != nil:
    body_600018 = body
  result = call_600017.call(nil, nil, nil, nil, body_600018)

var deleteConfigRule* = Call_DeleteConfigRule_600004(name: "deleteConfigRule",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteConfigRule",
    validator: validate_DeleteConfigRule_600005, base: "/",
    url: url_DeleteConfigRule_600006, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationAggregator_600019 = ref object of OpenApiRestCall_599368
proc url_DeleteConfigurationAggregator_600021(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConfigurationAggregator_600020(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600022 = header.getOrDefault("X-Amz-Date")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Date", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Security-Token")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Security-Token", valid_600023
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600024 = header.getOrDefault("X-Amz-Target")
  valid_600024 = validateParameter(valid_600024, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteConfigurationAggregator"))
  if valid_600024 != nil:
    section.add "X-Amz-Target", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Content-Sha256", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Algorithm")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Algorithm", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Signature")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Signature", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-SignedHeaders", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Credential")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Credential", valid_600029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600031: Call_DeleteConfigurationAggregator_600019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified configuration aggregator and the aggregated data associated with the aggregator.
  ## 
  let valid = call_600031.validator(path, query, header, formData, body)
  let scheme = call_600031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600031.url(scheme.get, call_600031.host, call_600031.base,
                         call_600031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600031, url, valid)

proc call*(call_600032: Call_DeleteConfigurationAggregator_600019; body: JsonNode): Recallable =
  ## deleteConfigurationAggregator
  ## Deletes the specified configuration aggregator and the aggregated data associated with the aggregator.
  ##   body: JObject (required)
  var body_600033 = newJObject()
  if body != nil:
    body_600033 = body
  result = call_600032.call(nil, nil, nil, nil, body_600033)

var deleteConfigurationAggregator* = Call_DeleteConfigurationAggregator_600019(
    name: "deleteConfigurationAggregator", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteConfigurationAggregator",
    validator: validate_DeleteConfigurationAggregator_600020, base: "/",
    url: url_DeleteConfigurationAggregator_600021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationRecorder_600034 = ref object of OpenApiRestCall_599368
proc url_DeleteConfigurationRecorder_600036(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConfigurationRecorder_600035(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600037 = header.getOrDefault("X-Amz-Date")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Date", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Security-Token")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Security-Token", valid_600038
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600039 = header.getOrDefault("X-Amz-Target")
  valid_600039 = validateParameter(valid_600039, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteConfigurationRecorder"))
  if valid_600039 != nil:
    section.add "X-Amz-Target", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Content-Sha256", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Algorithm")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Algorithm", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Signature")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Signature", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-SignedHeaders", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Credential")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Credential", valid_600044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600046: Call_DeleteConfigurationRecorder_600034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the configuration recorder.</p> <p>After the configuration recorder is deleted, AWS Config will not record resource configuration changes until you create a new configuration recorder.</p> <p>This action does not delete the configuration information that was previously recorded. You will be able to access the previously recorded information by using the <code>GetResourceConfigHistory</code> action, but you will not be able to access this information in the AWS Config console until you create a new configuration recorder.</p>
  ## 
  let valid = call_600046.validator(path, query, header, formData, body)
  let scheme = call_600046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600046.url(scheme.get, call_600046.host, call_600046.base,
                         call_600046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600046, url, valid)

proc call*(call_600047: Call_DeleteConfigurationRecorder_600034; body: JsonNode): Recallable =
  ## deleteConfigurationRecorder
  ## <p>Deletes the configuration recorder.</p> <p>After the configuration recorder is deleted, AWS Config will not record resource configuration changes until you create a new configuration recorder.</p> <p>This action does not delete the configuration information that was previously recorded. You will be able to access the previously recorded information by using the <code>GetResourceConfigHistory</code> action, but you will not be able to access this information in the AWS Config console until you create a new configuration recorder.</p>
  ##   body: JObject (required)
  var body_600048 = newJObject()
  if body != nil:
    body_600048 = body
  result = call_600047.call(nil, nil, nil, nil, body_600048)

var deleteConfigurationRecorder* = Call_DeleteConfigurationRecorder_600034(
    name: "deleteConfigurationRecorder", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteConfigurationRecorder",
    validator: validate_DeleteConfigurationRecorder_600035, base: "/",
    url: url_DeleteConfigurationRecorder_600036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConformancePack_600049 = ref object of OpenApiRestCall_599368
proc url_DeleteConformancePack_600051(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConformancePack_600050(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600052 = header.getOrDefault("X-Amz-Date")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Date", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Security-Token")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Security-Token", valid_600053
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600054 = header.getOrDefault("X-Amz-Target")
  valid_600054 = validateParameter(valid_600054, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteConformancePack"))
  if valid_600054 != nil:
    section.add "X-Amz-Target", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Content-Sha256", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Algorithm")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Algorithm", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Signature")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Signature", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-SignedHeaders", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Credential")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Credential", valid_600059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600061: Call_DeleteConformancePack_600049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified conformance pack and all the AWS Config rules, remediation actions, and all evaluation results within that conformance pack.</p> <p>AWS Config sets the conformance pack to <code>DELETE_IN_PROGRESS</code> until the deletion is complete. You cannot update a conformance pack while it is in this state.</p>
  ## 
  let valid = call_600061.validator(path, query, header, formData, body)
  let scheme = call_600061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600061.url(scheme.get, call_600061.host, call_600061.base,
                         call_600061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600061, url, valid)

proc call*(call_600062: Call_DeleteConformancePack_600049; body: JsonNode): Recallable =
  ## deleteConformancePack
  ## <p>Deletes the specified conformance pack and all the AWS Config rules, remediation actions, and all evaluation results within that conformance pack.</p> <p>AWS Config sets the conformance pack to <code>DELETE_IN_PROGRESS</code> until the deletion is complete. You cannot update a conformance pack while it is in this state.</p>
  ##   body: JObject (required)
  var body_600063 = newJObject()
  if body != nil:
    body_600063 = body
  result = call_600062.call(nil, nil, nil, nil, body_600063)

var deleteConformancePack* = Call_DeleteConformancePack_600049(
    name: "deleteConformancePack", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteConformancePack",
    validator: validate_DeleteConformancePack_600050, base: "/",
    url: url_DeleteConformancePack_600051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeliveryChannel_600064 = ref object of OpenApiRestCall_599368
proc url_DeleteDeliveryChannel_600066(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDeliveryChannel_600065(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600067 = header.getOrDefault("X-Amz-Date")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Date", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Security-Token")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Security-Token", valid_600068
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600069 = header.getOrDefault("X-Amz-Target")
  valid_600069 = validateParameter(valid_600069, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteDeliveryChannel"))
  if valid_600069 != nil:
    section.add "X-Amz-Target", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Content-Sha256", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Algorithm")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Algorithm", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Signature")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Signature", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-SignedHeaders", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Credential")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Credential", valid_600074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600076: Call_DeleteDeliveryChannel_600064; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the delivery channel.</p> <p>Before you can delete the delivery channel, you must stop the configuration recorder by using the <a>StopConfigurationRecorder</a> action.</p>
  ## 
  let valid = call_600076.validator(path, query, header, formData, body)
  let scheme = call_600076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600076.url(scheme.get, call_600076.host, call_600076.base,
                         call_600076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600076, url, valid)

proc call*(call_600077: Call_DeleteDeliveryChannel_600064; body: JsonNode): Recallable =
  ## deleteDeliveryChannel
  ## <p>Deletes the delivery channel.</p> <p>Before you can delete the delivery channel, you must stop the configuration recorder by using the <a>StopConfigurationRecorder</a> action.</p>
  ##   body: JObject (required)
  var body_600078 = newJObject()
  if body != nil:
    body_600078 = body
  result = call_600077.call(nil, nil, nil, nil, body_600078)

var deleteDeliveryChannel* = Call_DeleteDeliveryChannel_600064(
    name: "deleteDeliveryChannel", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteDeliveryChannel",
    validator: validate_DeleteDeliveryChannel_600065, base: "/",
    url: url_DeleteDeliveryChannel_600066, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEvaluationResults_600079 = ref object of OpenApiRestCall_599368
proc url_DeleteEvaluationResults_600081(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEvaluationResults_600080(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600082 = header.getOrDefault("X-Amz-Date")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Date", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Security-Token")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Security-Token", valid_600083
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600084 = header.getOrDefault("X-Amz-Target")
  valid_600084 = validateParameter(valid_600084, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteEvaluationResults"))
  if valid_600084 != nil:
    section.add "X-Amz-Target", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Content-Sha256", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Algorithm")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Algorithm", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Signature")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Signature", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-SignedHeaders", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Credential")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Credential", valid_600089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600091: Call_DeleteEvaluationResults_600079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the evaluation results for the specified AWS Config rule. You can specify one AWS Config rule per request. After you delete the evaluation results, you can call the <a>StartConfigRulesEvaluation</a> API to start evaluating your AWS resources against the rule.
  ## 
  let valid = call_600091.validator(path, query, header, formData, body)
  let scheme = call_600091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600091.url(scheme.get, call_600091.host, call_600091.base,
                         call_600091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600091, url, valid)

proc call*(call_600092: Call_DeleteEvaluationResults_600079; body: JsonNode): Recallable =
  ## deleteEvaluationResults
  ## Deletes the evaluation results for the specified AWS Config rule. You can specify one AWS Config rule per request. After you delete the evaluation results, you can call the <a>StartConfigRulesEvaluation</a> API to start evaluating your AWS resources against the rule.
  ##   body: JObject (required)
  var body_600093 = newJObject()
  if body != nil:
    body_600093 = body
  result = call_600092.call(nil, nil, nil, nil, body_600093)

var deleteEvaluationResults* = Call_DeleteEvaluationResults_600079(
    name: "deleteEvaluationResults", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteEvaluationResults",
    validator: validate_DeleteEvaluationResults_600080, base: "/",
    url: url_DeleteEvaluationResults_600081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOrganizationConfigRule_600094 = ref object of OpenApiRestCall_599368
proc url_DeleteOrganizationConfigRule_600096(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteOrganizationConfigRule_600095(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600097 = header.getOrDefault("X-Amz-Date")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Date", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Security-Token")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Security-Token", valid_600098
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600099 = header.getOrDefault("X-Amz-Target")
  valid_600099 = validateParameter(valid_600099, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteOrganizationConfigRule"))
  if valid_600099 != nil:
    section.add "X-Amz-Target", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Content-Sha256", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Algorithm")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Algorithm", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Signature")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Signature", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-SignedHeaders", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Credential")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Credential", valid_600104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600106: Call_DeleteOrganizationConfigRule_600094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified organization config rule and all of its evaluation results from all member accounts in that organization. Only a master account can delete an organization config rule.</p> <p>AWS Config sets the state of a rule to DELETE_IN_PROGRESS until the deletion is complete. You cannot update a rule while it is in this state.</p>
  ## 
  let valid = call_600106.validator(path, query, header, formData, body)
  let scheme = call_600106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600106.url(scheme.get, call_600106.host, call_600106.base,
                         call_600106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600106, url, valid)

proc call*(call_600107: Call_DeleteOrganizationConfigRule_600094; body: JsonNode): Recallable =
  ## deleteOrganizationConfigRule
  ## <p>Deletes the specified organization config rule and all of its evaluation results from all member accounts in that organization. Only a master account can delete an organization config rule.</p> <p>AWS Config sets the state of a rule to DELETE_IN_PROGRESS until the deletion is complete. You cannot update a rule while it is in this state.</p>
  ##   body: JObject (required)
  var body_600108 = newJObject()
  if body != nil:
    body_600108 = body
  result = call_600107.call(nil, nil, nil, nil, body_600108)

var deleteOrganizationConfigRule* = Call_DeleteOrganizationConfigRule_600094(
    name: "deleteOrganizationConfigRule", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteOrganizationConfigRule",
    validator: validate_DeleteOrganizationConfigRule_600095, base: "/",
    url: url_DeleteOrganizationConfigRule_600096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOrganizationConformancePack_600109 = ref object of OpenApiRestCall_599368
proc url_DeleteOrganizationConformancePack_600111(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteOrganizationConformancePack_600110(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600112 = header.getOrDefault("X-Amz-Date")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Date", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Security-Token")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Security-Token", valid_600113
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600114 = header.getOrDefault("X-Amz-Target")
  valid_600114 = validateParameter(valid_600114, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteOrganizationConformancePack"))
  if valid_600114 != nil:
    section.add "X-Amz-Target", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Content-Sha256", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Algorithm")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Algorithm", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Signature")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Signature", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-SignedHeaders", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Credential")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Credential", valid_600119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600121: Call_DeleteOrganizationConformancePack_600109;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the specified organization conformance pack and all of the config rules and remediation actions from all member accounts in that organization. Only a master account can delete an organization conformance pack.</p> <p>AWS Config sets the state of a conformance pack to DELETE_IN_PROGRESS until the deletion is complete. You cannot update a conformance pack while it is in this state. </p>
  ## 
  let valid = call_600121.validator(path, query, header, formData, body)
  let scheme = call_600121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600121.url(scheme.get, call_600121.host, call_600121.base,
                         call_600121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600121, url, valid)

proc call*(call_600122: Call_DeleteOrganizationConformancePack_600109;
          body: JsonNode): Recallable =
  ## deleteOrganizationConformancePack
  ## <p>Deletes the specified organization conformance pack and all of the config rules and remediation actions from all member accounts in that organization. Only a master account can delete an organization conformance pack.</p> <p>AWS Config sets the state of a conformance pack to DELETE_IN_PROGRESS until the deletion is complete. You cannot update a conformance pack while it is in this state. </p>
  ##   body: JObject (required)
  var body_600123 = newJObject()
  if body != nil:
    body_600123 = body
  result = call_600122.call(nil, nil, nil, nil, body_600123)

var deleteOrganizationConformancePack* = Call_DeleteOrganizationConformancePack_600109(
    name: "deleteOrganizationConformancePack", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DeleteOrganizationConformancePack",
    validator: validate_DeleteOrganizationConformancePack_600110, base: "/",
    url: url_DeleteOrganizationConformancePack_600111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePendingAggregationRequest_600124 = ref object of OpenApiRestCall_599368
proc url_DeletePendingAggregationRequest_600126(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePendingAggregationRequest_600125(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600127 = header.getOrDefault("X-Amz-Date")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Date", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Security-Token")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Security-Token", valid_600128
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600129 = header.getOrDefault("X-Amz-Target")
  valid_600129 = validateParameter(valid_600129, JString, required = true, default = newJString(
      "StarlingDoveService.DeletePendingAggregationRequest"))
  if valid_600129 != nil:
    section.add "X-Amz-Target", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Content-Sha256", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Algorithm")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Algorithm", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Signature")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Signature", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-SignedHeaders", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Credential")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Credential", valid_600134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600136: Call_DeletePendingAggregationRequest_600124;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes pending authorization requests for a specified aggregator account in a specified region.
  ## 
  let valid = call_600136.validator(path, query, header, formData, body)
  let scheme = call_600136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600136.url(scheme.get, call_600136.host, call_600136.base,
                         call_600136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600136, url, valid)

proc call*(call_600137: Call_DeletePendingAggregationRequest_600124; body: JsonNode): Recallable =
  ## deletePendingAggregationRequest
  ## Deletes pending authorization requests for a specified aggregator account in a specified region.
  ##   body: JObject (required)
  var body_600138 = newJObject()
  if body != nil:
    body_600138 = body
  result = call_600137.call(nil, nil, nil, nil, body_600138)

var deletePendingAggregationRequest* = Call_DeletePendingAggregationRequest_600124(
    name: "deletePendingAggregationRequest", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DeletePendingAggregationRequest",
    validator: validate_DeletePendingAggregationRequest_600125, base: "/",
    url: url_DeletePendingAggregationRequest_600126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRemediationConfiguration_600139 = ref object of OpenApiRestCall_599368
proc url_DeleteRemediationConfiguration_600141(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRemediationConfiguration_600140(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600142 = header.getOrDefault("X-Amz-Date")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Date", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Security-Token")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Security-Token", valid_600143
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600144 = header.getOrDefault("X-Amz-Target")
  valid_600144 = validateParameter(valid_600144, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteRemediationConfiguration"))
  if valid_600144 != nil:
    section.add "X-Amz-Target", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Content-Sha256", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Algorithm")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Algorithm", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Signature")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Signature", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-SignedHeaders", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Credential")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Credential", valid_600149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600151: Call_DeleteRemediationConfiguration_600139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the remediation configuration.
  ## 
  let valid = call_600151.validator(path, query, header, formData, body)
  let scheme = call_600151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600151.url(scheme.get, call_600151.host, call_600151.base,
                         call_600151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600151, url, valid)

proc call*(call_600152: Call_DeleteRemediationConfiguration_600139; body: JsonNode): Recallable =
  ## deleteRemediationConfiguration
  ## Deletes the remediation configuration.
  ##   body: JObject (required)
  var body_600153 = newJObject()
  if body != nil:
    body_600153 = body
  result = call_600152.call(nil, nil, nil, nil, body_600153)

var deleteRemediationConfiguration* = Call_DeleteRemediationConfiguration_600139(
    name: "deleteRemediationConfiguration", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteRemediationConfiguration",
    validator: validate_DeleteRemediationConfiguration_600140, base: "/",
    url: url_DeleteRemediationConfiguration_600141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRemediationExceptions_600154 = ref object of OpenApiRestCall_599368
proc url_DeleteRemediationExceptions_600156(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRemediationExceptions_600155(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600157 = header.getOrDefault("X-Amz-Date")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Date", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Security-Token")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Security-Token", valid_600158
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600159 = header.getOrDefault("X-Amz-Target")
  valid_600159 = validateParameter(valid_600159, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteRemediationExceptions"))
  if valid_600159 != nil:
    section.add "X-Amz-Target", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Content-Sha256", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Algorithm")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Algorithm", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-Signature")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Signature", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-SignedHeaders", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-Credential")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-Credential", valid_600164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600166: Call_DeleteRemediationExceptions_600154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes one or more remediation exceptions mentioned in the resource keys.
  ## 
  let valid = call_600166.validator(path, query, header, formData, body)
  let scheme = call_600166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600166.url(scheme.get, call_600166.host, call_600166.base,
                         call_600166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600166, url, valid)

proc call*(call_600167: Call_DeleteRemediationExceptions_600154; body: JsonNode): Recallable =
  ## deleteRemediationExceptions
  ## Deletes one or more remediation exceptions mentioned in the resource keys.
  ##   body: JObject (required)
  var body_600168 = newJObject()
  if body != nil:
    body_600168 = body
  result = call_600167.call(nil, nil, nil, nil, body_600168)

var deleteRemediationExceptions* = Call_DeleteRemediationExceptions_600154(
    name: "deleteRemediationExceptions", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteRemediationExceptions",
    validator: validate_DeleteRemediationExceptions_600155, base: "/",
    url: url_DeleteRemediationExceptions_600156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceConfig_600169 = ref object of OpenApiRestCall_599368
proc url_DeleteResourceConfig_600171(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteResourceConfig_600170(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600172 = header.getOrDefault("X-Amz-Date")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Date", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Security-Token")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Security-Token", valid_600173
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600174 = header.getOrDefault("X-Amz-Target")
  valid_600174 = validateParameter(valid_600174, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteResourceConfig"))
  if valid_600174 != nil:
    section.add "X-Amz-Target", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Content-Sha256", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Algorithm")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Algorithm", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Signature")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Signature", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-SignedHeaders", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-Credential")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Credential", valid_600179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600181: Call_DeleteResourceConfig_600169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Records the configuration state for a custom resource that has been deleted. This API records a new ConfigurationItem with a ResourceDeleted status. You can retrieve the ConfigurationItems recorded for this resource in your AWS Config History. 
  ## 
  let valid = call_600181.validator(path, query, header, formData, body)
  let scheme = call_600181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600181.url(scheme.get, call_600181.host, call_600181.base,
                         call_600181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600181, url, valid)

proc call*(call_600182: Call_DeleteResourceConfig_600169; body: JsonNode): Recallable =
  ## deleteResourceConfig
  ## Records the configuration state for a custom resource that has been deleted. This API records a new ConfigurationItem with a ResourceDeleted status. You can retrieve the ConfigurationItems recorded for this resource in your AWS Config History. 
  ##   body: JObject (required)
  var body_600183 = newJObject()
  if body != nil:
    body_600183 = body
  result = call_600182.call(nil, nil, nil, nil, body_600183)

var deleteResourceConfig* = Call_DeleteResourceConfig_600169(
    name: "deleteResourceConfig", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteResourceConfig",
    validator: validate_DeleteResourceConfig_600170, base: "/",
    url: url_DeleteResourceConfig_600171, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRetentionConfiguration_600184 = ref object of OpenApiRestCall_599368
proc url_DeleteRetentionConfiguration_600186(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRetentionConfiguration_600185(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600187 = header.getOrDefault("X-Amz-Date")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Date", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-Security-Token")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Security-Token", valid_600188
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600189 = header.getOrDefault("X-Amz-Target")
  valid_600189 = validateParameter(valid_600189, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteRetentionConfiguration"))
  if valid_600189 != nil:
    section.add "X-Amz-Target", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Content-Sha256", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Algorithm")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Algorithm", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Signature")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Signature", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-SignedHeaders", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-Credential")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Credential", valid_600194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600196: Call_DeleteRetentionConfiguration_600184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the retention configuration.
  ## 
  let valid = call_600196.validator(path, query, header, formData, body)
  let scheme = call_600196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600196.url(scheme.get, call_600196.host, call_600196.base,
                         call_600196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600196, url, valid)

proc call*(call_600197: Call_DeleteRetentionConfiguration_600184; body: JsonNode): Recallable =
  ## deleteRetentionConfiguration
  ## Deletes the retention configuration.
  ##   body: JObject (required)
  var body_600198 = newJObject()
  if body != nil:
    body_600198 = body
  result = call_600197.call(nil, nil, nil, nil, body_600198)

var deleteRetentionConfiguration* = Call_DeleteRetentionConfiguration_600184(
    name: "deleteRetentionConfiguration", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteRetentionConfiguration",
    validator: validate_DeleteRetentionConfiguration_600185, base: "/",
    url: url_DeleteRetentionConfiguration_600186,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeliverConfigSnapshot_600199 = ref object of OpenApiRestCall_599368
proc url_DeliverConfigSnapshot_600201(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeliverConfigSnapshot_600200(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600202 = header.getOrDefault("X-Amz-Date")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Date", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-Security-Token")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Security-Token", valid_600203
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600204 = header.getOrDefault("X-Amz-Target")
  valid_600204 = validateParameter(valid_600204, JString, required = true, default = newJString(
      "StarlingDoveService.DeliverConfigSnapshot"))
  if valid_600204 != nil:
    section.add "X-Amz-Target", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Content-Sha256", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Algorithm")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Algorithm", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-Signature")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Signature", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-SignedHeaders", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-Credential")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Credential", valid_600209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600211: Call_DeliverConfigSnapshot_600199; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Schedules delivery of a configuration snapshot to the Amazon S3 bucket in the specified delivery channel. After the delivery has started, AWS Config sends the following notifications using an Amazon SNS topic that you have specified.</p> <ul> <li> <p>Notification of the start of the delivery.</p> </li> <li> <p>Notification of the completion of the delivery, if the delivery was successfully completed.</p> </li> <li> <p>Notification of delivery failure, if the delivery failed.</p> </li> </ul>
  ## 
  let valid = call_600211.validator(path, query, header, formData, body)
  let scheme = call_600211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600211.url(scheme.get, call_600211.host, call_600211.base,
                         call_600211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600211, url, valid)

proc call*(call_600212: Call_DeliverConfigSnapshot_600199; body: JsonNode): Recallable =
  ## deliverConfigSnapshot
  ## <p>Schedules delivery of a configuration snapshot to the Amazon S3 bucket in the specified delivery channel. After the delivery has started, AWS Config sends the following notifications using an Amazon SNS topic that you have specified.</p> <ul> <li> <p>Notification of the start of the delivery.</p> </li> <li> <p>Notification of the completion of the delivery, if the delivery was successfully completed.</p> </li> <li> <p>Notification of delivery failure, if the delivery failed.</p> </li> </ul>
  ##   body: JObject (required)
  var body_600213 = newJObject()
  if body != nil:
    body_600213 = body
  result = call_600212.call(nil, nil, nil, nil, body_600213)

var deliverConfigSnapshot* = Call_DeliverConfigSnapshot_600199(
    name: "deliverConfigSnapshot", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeliverConfigSnapshot",
    validator: validate_DeliverConfigSnapshot_600200, base: "/",
    url: url_DeliverConfigSnapshot_600201, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAggregateComplianceByConfigRules_600214 = ref object of OpenApiRestCall_599368
proc url_DescribeAggregateComplianceByConfigRules_600216(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAggregateComplianceByConfigRules_600215(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600217 = header.getOrDefault("X-Amz-Date")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Date", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-Security-Token")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Security-Token", valid_600218
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600219 = header.getOrDefault("X-Amz-Target")
  valid_600219 = validateParameter(valid_600219, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeAggregateComplianceByConfigRules"))
  if valid_600219 != nil:
    section.add "X-Amz-Target", valid_600219
  var valid_600220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-Content-Sha256", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Algorithm")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Algorithm", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-Signature")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Signature", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-SignedHeaders", valid_600223
  var valid_600224 = header.getOrDefault("X-Amz-Credential")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Credential", valid_600224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600226: Call_DescribeAggregateComplianceByConfigRules_600214;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of compliant and noncompliant rules with the number of resources for compliant and noncompliant rules. </p> <note> <p>The results can return an empty result page, but if you have a <code>nextToken</code>, the results are displayed on the next page.</p> </note>
  ## 
  let valid = call_600226.validator(path, query, header, formData, body)
  let scheme = call_600226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600226.url(scheme.get, call_600226.host, call_600226.base,
                         call_600226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600226, url, valid)

proc call*(call_600227: Call_DescribeAggregateComplianceByConfigRules_600214;
          body: JsonNode): Recallable =
  ## describeAggregateComplianceByConfigRules
  ## <p>Returns a list of compliant and noncompliant rules with the number of resources for compliant and noncompliant rules. </p> <note> <p>The results can return an empty result page, but if you have a <code>nextToken</code>, the results are displayed on the next page.</p> </note>
  ##   body: JObject (required)
  var body_600228 = newJObject()
  if body != nil:
    body_600228 = body
  result = call_600227.call(nil, nil, nil, nil, body_600228)

var describeAggregateComplianceByConfigRules* = Call_DescribeAggregateComplianceByConfigRules_600214(
    name: "describeAggregateComplianceByConfigRules", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeAggregateComplianceByConfigRules",
    validator: validate_DescribeAggregateComplianceByConfigRules_600215,
    base: "/", url: url_DescribeAggregateComplianceByConfigRules_600216,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAggregationAuthorizations_600229 = ref object of OpenApiRestCall_599368
proc url_DescribeAggregationAuthorizations_600231(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAggregationAuthorizations_600230(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600232 = header.getOrDefault("X-Amz-Date")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Date", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-Security-Token")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Security-Token", valid_600233
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600234 = header.getOrDefault("X-Amz-Target")
  valid_600234 = validateParameter(valid_600234, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeAggregationAuthorizations"))
  if valid_600234 != nil:
    section.add "X-Amz-Target", valid_600234
  var valid_600235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-Content-Sha256", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Algorithm")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Algorithm", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-Signature")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-Signature", valid_600237
  var valid_600238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-SignedHeaders", valid_600238
  var valid_600239 = header.getOrDefault("X-Amz-Credential")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Credential", valid_600239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600241: Call_DescribeAggregationAuthorizations_600229;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of authorizations granted to various aggregator accounts and regions.
  ## 
  let valid = call_600241.validator(path, query, header, formData, body)
  let scheme = call_600241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600241.url(scheme.get, call_600241.host, call_600241.base,
                         call_600241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600241, url, valid)

proc call*(call_600242: Call_DescribeAggregationAuthorizations_600229;
          body: JsonNode): Recallable =
  ## describeAggregationAuthorizations
  ## Returns a list of authorizations granted to various aggregator accounts and regions.
  ##   body: JObject (required)
  var body_600243 = newJObject()
  if body != nil:
    body_600243 = body
  result = call_600242.call(nil, nil, nil, nil, body_600243)

var describeAggregationAuthorizations* = Call_DescribeAggregationAuthorizations_600229(
    name: "describeAggregationAuthorizations", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeAggregationAuthorizations",
    validator: validate_DescribeAggregationAuthorizations_600230, base: "/",
    url: url_DescribeAggregationAuthorizations_600231,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComplianceByConfigRule_600244 = ref object of OpenApiRestCall_599368
proc url_DescribeComplianceByConfigRule_600246(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeComplianceByConfigRule_600245(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600247 = header.getOrDefault("X-Amz-Date")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Date", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-Security-Token")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Security-Token", valid_600248
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600249 = header.getOrDefault("X-Amz-Target")
  valid_600249 = validateParameter(valid_600249, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeComplianceByConfigRule"))
  if valid_600249 != nil:
    section.add "X-Amz-Target", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Content-Sha256", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-Algorithm")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-Algorithm", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-Signature")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-Signature", valid_600252
  var valid_600253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-SignedHeaders", valid_600253
  var valid_600254 = header.getOrDefault("X-Amz-Credential")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-Credential", valid_600254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600256: Call_DescribeComplianceByConfigRule_600244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Indicates whether the specified AWS Config rules are compliant. If a rule is noncompliant, this action returns the number of AWS resources that do not comply with the rule.</p> <p>A rule is compliant if all of the evaluated resources comply with it. It is noncompliant if any of these resources do not comply.</p> <p>If AWS Config has no current evaluation results for the rule, it returns <code>INSUFFICIENT_DATA</code>. This result might indicate one of the following conditions:</p> <ul> <li> <p>AWS Config has never invoked an evaluation for the rule. To check whether it has, use the <code>DescribeConfigRuleEvaluationStatus</code> action to get the <code>LastSuccessfulInvocationTime</code> and <code>LastFailedInvocationTime</code>.</p> </li> <li> <p>The rule's AWS Lambda function is failing to send evaluation results to AWS Config. Verify that the role you assigned to your configuration recorder includes the <code>config:PutEvaluations</code> permission. If the rule is a custom rule, verify that the AWS Lambda execution role includes the <code>config:PutEvaluations</code> permission.</p> </li> <li> <p>The rule's AWS Lambda function has returned <code>NOT_APPLICABLE</code> for all evaluation results. This can occur if the resources were deleted or removed from the rule's scope.</p> </li> </ul>
  ## 
  let valid = call_600256.validator(path, query, header, formData, body)
  let scheme = call_600256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600256.url(scheme.get, call_600256.host, call_600256.base,
                         call_600256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600256, url, valid)

proc call*(call_600257: Call_DescribeComplianceByConfigRule_600244; body: JsonNode): Recallable =
  ## describeComplianceByConfigRule
  ## <p>Indicates whether the specified AWS Config rules are compliant. If a rule is noncompliant, this action returns the number of AWS resources that do not comply with the rule.</p> <p>A rule is compliant if all of the evaluated resources comply with it. It is noncompliant if any of these resources do not comply.</p> <p>If AWS Config has no current evaluation results for the rule, it returns <code>INSUFFICIENT_DATA</code>. This result might indicate one of the following conditions:</p> <ul> <li> <p>AWS Config has never invoked an evaluation for the rule. To check whether it has, use the <code>DescribeConfigRuleEvaluationStatus</code> action to get the <code>LastSuccessfulInvocationTime</code> and <code>LastFailedInvocationTime</code>.</p> </li> <li> <p>The rule's AWS Lambda function is failing to send evaluation results to AWS Config. Verify that the role you assigned to your configuration recorder includes the <code>config:PutEvaluations</code> permission. If the rule is a custom rule, verify that the AWS Lambda execution role includes the <code>config:PutEvaluations</code> permission.</p> </li> <li> <p>The rule's AWS Lambda function has returned <code>NOT_APPLICABLE</code> for all evaluation results. This can occur if the resources were deleted or removed from the rule's scope.</p> </li> </ul>
  ##   body: JObject (required)
  var body_600258 = newJObject()
  if body != nil:
    body_600258 = body
  result = call_600257.call(nil, nil, nil, nil, body_600258)

var describeComplianceByConfigRule* = Call_DescribeComplianceByConfigRule_600244(
    name: "describeComplianceByConfigRule", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeComplianceByConfigRule",
    validator: validate_DescribeComplianceByConfigRule_600245, base: "/",
    url: url_DescribeComplianceByConfigRule_600246,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComplianceByResource_600259 = ref object of OpenApiRestCall_599368
proc url_DescribeComplianceByResource_600261(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeComplianceByResource_600260(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600262 = header.getOrDefault("X-Amz-Date")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Date", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Security-Token")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Security-Token", valid_600263
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600264 = header.getOrDefault("X-Amz-Target")
  valid_600264 = validateParameter(valid_600264, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeComplianceByResource"))
  if valid_600264 != nil:
    section.add "X-Amz-Target", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-Content-Sha256", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-Algorithm")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-Algorithm", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-Signature")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-Signature", valid_600267
  var valid_600268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600268 = validateParameter(valid_600268, JString, required = false,
                                 default = nil)
  if valid_600268 != nil:
    section.add "X-Amz-SignedHeaders", valid_600268
  var valid_600269 = header.getOrDefault("X-Amz-Credential")
  valid_600269 = validateParameter(valid_600269, JString, required = false,
                                 default = nil)
  if valid_600269 != nil:
    section.add "X-Amz-Credential", valid_600269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600271: Call_DescribeComplianceByResource_600259; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Indicates whether the specified AWS resources are compliant. If a resource is noncompliant, this action returns the number of AWS Config rules that the resource does not comply with.</p> <p>A resource is compliant if it complies with all the AWS Config rules that evaluate it. It is noncompliant if it does not comply with one or more of these rules.</p> <p>If AWS Config has no current evaluation results for the resource, it returns <code>INSUFFICIENT_DATA</code>. This result might indicate one of the following conditions about the rules that evaluate the resource:</p> <ul> <li> <p>AWS Config has never invoked an evaluation for the rule. To check whether it has, use the <code>DescribeConfigRuleEvaluationStatus</code> action to get the <code>LastSuccessfulInvocationTime</code> and <code>LastFailedInvocationTime</code>.</p> </li> <li> <p>The rule's AWS Lambda function is failing to send evaluation results to AWS Config. Verify that the role that you assigned to your configuration recorder includes the <code>config:PutEvaluations</code> permission. If the rule is a custom rule, verify that the AWS Lambda execution role includes the <code>config:PutEvaluations</code> permission.</p> </li> <li> <p>The rule's AWS Lambda function has returned <code>NOT_APPLICABLE</code> for all evaluation results. This can occur if the resources were deleted or removed from the rule's scope.</p> </li> </ul>
  ## 
  let valid = call_600271.validator(path, query, header, formData, body)
  let scheme = call_600271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600271.url(scheme.get, call_600271.host, call_600271.base,
                         call_600271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600271, url, valid)

proc call*(call_600272: Call_DescribeComplianceByResource_600259; body: JsonNode): Recallable =
  ## describeComplianceByResource
  ## <p>Indicates whether the specified AWS resources are compliant. If a resource is noncompliant, this action returns the number of AWS Config rules that the resource does not comply with.</p> <p>A resource is compliant if it complies with all the AWS Config rules that evaluate it. It is noncompliant if it does not comply with one or more of these rules.</p> <p>If AWS Config has no current evaluation results for the resource, it returns <code>INSUFFICIENT_DATA</code>. This result might indicate one of the following conditions about the rules that evaluate the resource:</p> <ul> <li> <p>AWS Config has never invoked an evaluation for the rule. To check whether it has, use the <code>DescribeConfigRuleEvaluationStatus</code> action to get the <code>LastSuccessfulInvocationTime</code> and <code>LastFailedInvocationTime</code>.</p> </li> <li> <p>The rule's AWS Lambda function is failing to send evaluation results to AWS Config. Verify that the role that you assigned to your configuration recorder includes the <code>config:PutEvaluations</code> permission. If the rule is a custom rule, verify that the AWS Lambda execution role includes the <code>config:PutEvaluations</code> permission.</p> </li> <li> <p>The rule's AWS Lambda function has returned <code>NOT_APPLICABLE</code> for all evaluation results. This can occur if the resources were deleted or removed from the rule's scope.</p> </li> </ul>
  ##   body: JObject (required)
  var body_600273 = newJObject()
  if body != nil:
    body_600273 = body
  result = call_600272.call(nil, nil, nil, nil, body_600273)

var describeComplianceByResource* = Call_DescribeComplianceByResource_600259(
    name: "describeComplianceByResource", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeComplianceByResource",
    validator: validate_DescribeComplianceByResource_600260, base: "/",
    url: url_DescribeComplianceByResource_600261,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigRuleEvaluationStatus_600274 = ref object of OpenApiRestCall_599368
proc url_DescribeConfigRuleEvaluationStatus_600276(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConfigRuleEvaluationStatus_600275(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600277 = header.getOrDefault("X-Amz-Date")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Date", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-Security-Token")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Security-Token", valid_600278
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600279 = header.getOrDefault("X-Amz-Target")
  valid_600279 = validateParameter(valid_600279, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConfigRuleEvaluationStatus"))
  if valid_600279 != nil:
    section.add "X-Amz-Target", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Content-Sha256", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Algorithm")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Algorithm", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-Signature")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Signature", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-SignedHeaders", valid_600283
  var valid_600284 = header.getOrDefault("X-Amz-Credential")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-Credential", valid_600284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600286: Call_DescribeConfigRuleEvaluationStatus_600274;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns status information for each of your AWS managed Config rules. The status includes information such as the last time AWS Config invoked the rule, the last time AWS Config failed to invoke the rule, and the related error for the last failure.
  ## 
  let valid = call_600286.validator(path, query, header, formData, body)
  let scheme = call_600286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600286.url(scheme.get, call_600286.host, call_600286.base,
                         call_600286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600286, url, valid)

proc call*(call_600287: Call_DescribeConfigRuleEvaluationStatus_600274;
          body: JsonNode): Recallable =
  ## describeConfigRuleEvaluationStatus
  ## Returns status information for each of your AWS managed Config rules. The status includes information such as the last time AWS Config invoked the rule, the last time AWS Config failed to invoke the rule, and the related error for the last failure.
  ##   body: JObject (required)
  var body_600288 = newJObject()
  if body != nil:
    body_600288 = body
  result = call_600287.call(nil, nil, nil, nil, body_600288)

var describeConfigRuleEvaluationStatus* = Call_DescribeConfigRuleEvaluationStatus_600274(
    name: "describeConfigRuleEvaluationStatus", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeConfigRuleEvaluationStatus",
    validator: validate_DescribeConfigRuleEvaluationStatus_600275, base: "/",
    url: url_DescribeConfigRuleEvaluationStatus_600276,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigRules_600289 = ref object of OpenApiRestCall_599368
proc url_DescribeConfigRules_600291(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConfigRules_600290(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_600292 = header.getOrDefault("X-Amz-Date")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Date", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Security-Token")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Security-Token", valid_600293
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600294 = header.getOrDefault("X-Amz-Target")
  valid_600294 = validateParameter(valid_600294, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConfigRules"))
  if valid_600294 != nil:
    section.add "X-Amz-Target", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Content-Sha256", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Algorithm")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Algorithm", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-Signature")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-Signature", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-SignedHeaders", valid_600298
  var valid_600299 = header.getOrDefault("X-Amz-Credential")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Credential", valid_600299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600301: Call_DescribeConfigRules_600289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about your AWS Config rules.
  ## 
  let valid = call_600301.validator(path, query, header, formData, body)
  let scheme = call_600301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600301.url(scheme.get, call_600301.host, call_600301.base,
                         call_600301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600301, url, valid)

proc call*(call_600302: Call_DescribeConfigRules_600289; body: JsonNode): Recallable =
  ## describeConfigRules
  ## Returns details about your AWS Config rules.
  ##   body: JObject (required)
  var body_600303 = newJObject()
  if body != nil:
    body_600303 = body
  result = call_600302.call(nil, nil, nil, nil, body_600303)

var describeConfigRules* = Call_DescribeConfigRules_600289(
    name: "describeConfigRules", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeConfigRules",
    validator: validate_DescribeConfigRules_600290, base: "/",
    url: url_DescribeConfigRules_600291, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationAggregatorSourcesStatus_600304 = ref object of OpenApiRestCall_599368
proc url_DescribeConfigurationAggregatorSourcesStatus_600306(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConfigurationAggregatorSourcesStatus_600305(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600307 = header.getOrDefault("X-Amz-Date")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "X-Amz-Date", valid_600307
  var valid_600308 = header.getOrDefault("X-Amz-Security-Token")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Security-Token", valid_600308
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600309 = header.getOrDefault("X-Amz-Target")
  valid_600309 = validateParameter(valid_600309, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConfigurationAggregatorSourcesStatus"))
  if valid_600309 != nil:
    section.add "X-Amz-Target", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-Content-Sha256", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Algorithm")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Algorithm", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Signature")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Signature", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-SignedHeaders", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-Credential")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-Credential", valid_600314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600316: Call_DescribeConfigurationAggregatorSourcesStatus_600304;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns status information for sources within an aggregator. The status includes information about the last time AWS Config verified authorization between the source account and an aggregator account. In case of a failure, the status contains the related error code or message. 
  ## 
  let valid = call_600316.validator(path, query, header, formData, body)
  let scheme = call_600316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600316.url(scheme.get, call_600316.host, call_600316.base,
                         call_600316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600316, url, valid)

proc call*(call_600317: Call_DescribeConfigurationAggregatorSourcesStatus_600304;
          body: JsonNode): Recallable =
  ## describeConfigurationAggregatorSourcesStatus
  ## Returns status information for sources within an aggregator. The status includes information about the last time AWS Config verified authorization between the source account and an aggregator account. In case of a failure, the status contains the related error code or message. 
  ##   body: JObject (required)
  var body_600318 = newJObject()
  if body != nil:
    body_600318 = body
  result = call_600317.call(nil, nil, nil, nil, body_600318)

var describeConfigurationAggregatorSourcesStatus* = Call_DescribeConfigurationAggregatorSourcesStatus_600304(
    name: "describeConfigurationAggregatorSourcesStatus",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeConfigurationAggregatorSourcesStatus",
    validator: validate_DescribeConfigurationAggregatorSourcesStatus_600305,
    base: "/", url: url_DescribeConfigurationAggregatorSourcesStatus_600306,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationAggregators_600319 = ref object of OpenApiRestCall_599368
proc url_DescribeConfigurationAggregators_600321(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConfigurationAggregators_600320(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600322 = header.getOrDefault("X-Amz-Date")
  valid_600322 = validateParameter(valid_600322, JString, required = false,
                                 default = nil)
  if valid_600322 != nil:
    section.add "X-Amz-Date", valid_600322
  var valid_600323 = header.getOrDefault("X-Amz-Security-Token")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Security-Token", valid_600323
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600324 = header.getOrDefault("X-Amz-Target")
  valid_600324 = validateParameter(valid_600324, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConfigurationAggregators"))
  if valid_600324 != nil:
    section.add "X-Amz-Target", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Content-Sha256", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Algorithm")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Algorithm", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Signature")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Signature", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-SignedHeaders", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-Credential")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-Credential", valid_600329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600331: Call_DescribeConfigurationAggregators_600319;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the details of one or more configuration aggregators. If the configuration aggregator is not specified, this action returns the details for all the configuration aggregators associated with the account. 
  ## 
  let valid = call_600331.validator(path, query, header, formData, body)
  let scheme = call_600331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600331.url(scheme.get, call_600331.host, call_600331.base,
                         call_600331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600331, url, valid)

proc call*(call_600332: Call_DescribeConfigurationAggregators_600319;
          body: JsonNode): Recallable =
  ## describeConfigurationAggregators
  ## Returns the details of one or more configuration aggregators. If the configuration aggregator is not specified, this action returns the details for all the configuration aggregators associated with the account. 
  ##   body: JObject (required)
  var body_600333 = newJObject()
  if body != nil:
    body_600333 = body
  result = call_600332.call(nil, nil, nil, nil, body_600333)

var describeConfigurationAggregators* = Call_DescribeConfigurationAggregators_600319(
    name: "describeConfigurationAggregators", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeConfigurationAggregators",
    validator: validate_DescribeConfigurationAggregators_600320, base: "/",
    url: url_DescribeConfigurationAggregators_600321,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationRecorderStatus_600334 = ref object of OpenApiRestCall_599368
proc url_DescribeConfigurationRecorderStatus_600336(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConfigurationRecorderStatus_600335(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600337 = header.getOrDefault("X-Amz-Date")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-Date", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-Security-Token")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Security-Token", valid_600338
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600339 = header.getOrDefault("X-Amz-Target")
  valid_600339 = validateParameter(valid_600339, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConfigurationRecorderStatus"))
  if valid_600339 != nil:
    section.add "X-Amz-Target", valid_600339
  var valid_600340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600340 = validateParameter(valid_600340, JString, required = false,
                                 default = nil)
  if valid_600340 != nil:
    section.add "X-Amz-Content-Sha256", valid_600340
  var valid_600341 = header.getOrDefault("X-Amz-Algorithm")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-Algorithm", valid_600341
  var valid_600342 = header.getOrDefault("X-Amz-Signature")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "X-Amz-Signature", valid_600342
  var valid_600343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "X-Amz-SignedHeaders", valid_600343
  var valid_600344 = header.getOrDefault("X-Amz-Credential")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-Credential", valid_600344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600346: Call_DescribeConfigurationRecorderStatus_600334;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the current status of the specified configuration recorder. If a configuration recorder is not specified, this action returns the status of all configuration recorders associated with the account.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> </note>
  ## 
  let valid = call_600346.validator(path, query, header, formData, body)
  let scheme = call_600346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600346.url(scheme.get, call_600346.host, call_600346.base,
                         call_600346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600346, url, valid)

proc call*(call_600347: Call_DescribeConfigurationRecorderStatus_600334;
          body: JsonNode): Recallable =
  ## describeConfigurationRecorderStatus
  ## <p>Returns the current status of the specified configuration recorder. If a configuration recorder is not specified, this action returns the status of all configuration recorders associated with the account.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> </note>
  ##   body: JObject (required)
  var body_600348 = newJObject()
  if body != nil:
    body_600348 = body
  result = call_600347.call(nil, nil, nil, nil, body_600348)

var describeConfigurationRecorderStatus* = Call_DescribeConfigurationRecorderStatus_600334(
    name: "describeConfigurationRecorderStatus", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeConfigurationRecorderStatus",
    validator: validate_DescribeConfigurationRecorderStatus_600335, base: "/",
    url: url_DescribeConfigurationRecorderStatus_600336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationRecorders_600349 = ref object of OpenApiRestCall_599368
proc url_DescribeConfigurationRecorders_600351(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConfigurationRecorders_600350(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600352 = header.getOrDefault("X-Amz-Date")
  valid_600352 = validateParameter(valid_600352, JString, required = false,
                                 default = nil)
  if valid_600352 != nil:
    section.add "X-Amz-Date", valid_600352
  var valid_600353 = header.getOrDefault("X-Amz-Security-Token")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-Security-Token", valid_600353
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600354 = header.getOrDefault("X-Amz-Target")
  valid_600354 = validateParameter(valid_600354, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConfigurationRecorders"))
  if valid_600354 != nil:
    section.add "X-Amz-Target", valid_600354
  var valid_600355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600355 = validateParameter(valid_600355, JString, required = false,
                                 default = nil)
  if valid_600355 != nil:
    section.add "X-Amz-Content-Sha256", valid_600355
  var valid_600356 = header.getOrDefault("X-Amz-Algorithm")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-Algorithm", valid_600356
  var valid_600357 = header.getOrDefault("X-Amz-Signature")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Signature", valid_600357
  var valid_600358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "X-Amz-SignedHeaders", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-Credential")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Credential", valid_600359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600361: Call_DescribeConfigurationRecorders_600349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the details for the specified configuration recorders. If the configuration recorder is not specified, this action returns the details for all configuration recorders associated with the account.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> </note>
  ## 
  let valid = call_600361.validator(path, query, header, formData, body)
  let scheme = call_600361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600361.url(scheme.get, call_600361.host, call_600361.base,
                         call_600361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600361, url, valid)

proc call*(call_600362: Call_DescribeConfigurationRecorders_600349; body: JsonNode): Recallable =
  ## describeConfigurationRecorders
  ## <p>Returns the details for the specified configuration recorders. If the configuration recorder is not specified, this action returns the details for all configuration recorders associated with the account.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> </note>
  ##   body: JObject (required)
  var body_600363 = newJObject()
  if body != nil:
    body_600363 = body
  result = call_600362.call(nil, nil, nil, nil, body_600363)

var describeConfigurationRecorders* = Call_DescribeConfigurationRecorders_600349(
    name: "describeConfigurationRecorders", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeConfigurationRecorders",
    validator: validate_DescribeConfigurationRecorders_600350, base: "/",
    url: url_DescribeConfigurationRecorders_600351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConformancePackCompliance_600364 = ref object of OpenApiRestCall_599368
proc url_DescribeConformancePackCompliance_600366(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConformancePackCompliance_600365(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600367 = header.getOrDefault("X-Amz-Date")
  valid_600367 = validateParameter(valid_600367, JString, required = false,
                                 default = nil)
  if valid_600367 != nil:
    section.add "X-Amz-Date", valid_600367
  var valid_600368 = header.getOrDefault("X-Amz-Security-Token")
  valid_600368 = validateParameter(valid_600368, JString, required = false,
                                 default = nil)
  if valid_600368 != nil:
    section.add "X-Amz-Security-Token", valid_600368
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600369 = header.getOrDefault("X-Amz-Target")
  valid_600369 = validateParameter(valid_600369, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConformancePackCompliance"))
  if valid_600369 != nil:
    section.add "X-Amz-Target", valid_600369
  var valid_600370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600370 = validateParameter(valid_600370, JString, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "X-Amz-Content-Sha256", valid_600370
  var valid_600371 = header.getOrDefault("X-Amz-Algorithm")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-Algorithm", valid_600371
  var valid_600372 = header.getOrDefault("X-Amz-Signature")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Signature", valid_600372
  var valid_600373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600373 = validateParameter(valid_600373, JString, required = false,
                                 default = nil)
  if valid_600373 != nil:
    section.add "X-Amz-SignedHeaders", valid_600373
  var valid_600374 = header.getOrDefault("X-Amz-Credential")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-Credential", valid_600374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600376: Call_DescribeConformancePackCompliance_600364;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns compliance details for each rule in that conformance pack.</p> <note> <p>You must provide exact rule names.</p> </note>
  ## 
  let valid = call_600376.validator(path, query, header, formData, body)
  let scheme = call_600376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600376.url(scheme.get, call_600376.host, call_600376.base,
                         call_600376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600376, url, valid)

proc call*(call_600377: Call_DescribeConformancePackCompliance_600364;
          body: JsonNode): Recallable =
  ## describeConformancePackCompliance
  ## <p>Returns compliance details for each rule in that conformance pack.</p> <note> <p>You must provide exact rule names.</p> </note>
  ##   body: JObject (required)
  var body_600378 = newJObject()
  if body != nil:
    body_600378 = body
  result = call_600377.call(nil, nil, nil, nil, body_600378)

var describeConformancePackCompliance* = Call_DescribeConformancePackCompliance_600364(
    name: "describeConformancePackCompliance", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeConformancePackCompliance",
    validator: validate_DescribeConformancePackCompliance_600365, base: "/",
    url: url_DescribeConformancePackCompliance_600366,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConformancePackStatus_600379 = ref object of OpenApiRestCall_599368
proc url_DescribeConformancePackStatus_600381(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConformancePackStatus_600380(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600382 = header.getOrDefault("X-Amz-Date")
  valid_600382 = validateParameter(valid_600382, JString, required = false,
                                 default = nil)
  if valid_600382 != nil:
    section.add "X-Amz-Date", valid_600382
  var valid_600383 = header.getOrDefault("X-Amz-Security-Token")
  valid_600383 = validateParameter(valid_600383, JString, required = false,
                                 default = nil)
  if valid_600383 != nil:
    section.add "X-Amz-Security-Token", valid_600383
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600384 = header.getOrDefault("X-Amz-Target")
  valid_600384 = validateParameter(valid_600384, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConformancePackStatus"))
  if valid_600384 != nil:
    section.add "X-Amz-Target", valid_600384
  var valid_600385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600385 = validateParameter(valid_600385, JString, required = false,
                                 default = nil)
  if valid_600385 != nil:
    section.add "X-Amz-Content-Sha256", valid_600385
  var valid_600386 = header.getOrDefault("X-Amz-Algorithm")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "X-Amz-Algorithm", valid_600386
  var valid_600387 = header.getOrDefault("X-Amz-Signature")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-Signature", valid_600387
  var valid_600388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-SignedHeaders", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-Credential")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Credential", valid_600389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600391: Call_DescribeConformancePackStatus_600379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provides one or more conformance packs deployment status.</p> <note> <p>If there are no conformance packs then you will see an empty result.</p> </note>
  ## 
  let valid = call_600391.validator(path, query, header, formData, body)
  let scheme = call_600391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600391.url(scheme.get, call_600391.host, call_600391.base,
                         call_600391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600391, url, valid)

proc call*(call_600392: Call_DescribeConformancePackStatus_600379; body: JsonNode): Recallable =
  ## describeConformancePackStatus
  ## <p>Provides one or more conformance packs deployment status.</p> <note> <p>If there are no conformance packs then you will see an empty result.</p> </note>
  ##   body: JObject (required)
  var body_600393 = newJObject()
  if body != nil:
    body_600393 = body
  result = call_600392.call(nil, nil, nil, nil, body_600393)

var describeConformancePackStatus* = Call_DescribeConformancePackStatus_600379(
    name: "describeConformancePackStatus", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeConformancePackStatus",
    validator: validate_DescribeConformancePackStatus_600380, base: "/",
    url: url_DescribeConformancePackStatus_600381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConformancePacks_600394 = ref object of OpenApiRestCall_599368
proc url_DescribeConformancePacks_600396(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConformancePacks_600395(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600397 = header.getOrDefault("X-Amz-Date")
  valid_600397 = validateParameter(valid_600397, JString, required = false,
                                 default = nil)
  if valid_600397 != nil:
    section.add "X-Amz-Date", valid_600397
  var valid_600398 = header.getOrDefault("X-Amz-Security-Token")
  valid_600398 = validateParameter(valid_600398, JString, required = false,
                                 default = nil)
  if valid_600398 != nil:
    section.add "X-Amz-Security-Token", valid_600398
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600399 = header.getOrDefault("X-Amz-Target")
  valid_600399 = validateParameter(valid_600399, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConformancePacks"))
  if valid_600399 != nil:
    section.add "X-Amz-Target", valid_600399
  var valid_600400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "X-Amz-Content-Sha256", valid_600400
  var valid_600401 = header.getOrDefault("X-Amz-Algorithm")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-Algorithm", valid_600401
  var valid_600402 = header.getOrDefault("X-Amz-Signature")
  valid_600402 = validateParameter(valid_600402, JString, required = false,
                                 default = nil)
  if valid_600402 != nil:
    section.add "X-Amz-Signature", valid_600402
  var valid_600403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600403 = validateParameter(valid_600403, JString, required = false,
                                 default = nil)
  if valid_600403 != nil:
    section.add "X-Amz-SignedHeaders", valid_600403
  var valid_600404 = header.getOrDefault("X-Amz-Credential")
  valid_600404 = validateParameter(valid_600404, JString, required = false,
                                 default = nil)
  if valid_600404 != nil:
    section.add "X-Amz-Credential", valid_600404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600406: Call_DescribeConformancePacks_600394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of one or more conformance packs.
  ## 
  let valid = call_600406.validator(path, query, header, formData, body)
  let scheme = call_600406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600406.url(scheme.get, call_600406.host, call_600406.base,
                         call_600406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600406, url, valid)

proc call*(call_600407: Call_DescribeConformancePacks_600394; body: JsonNode): Recallable =
  ## describeConformancePacks
  ## Returns a list of one or more conformance packs.
  ##   body: JObject (required)
  var body_600408 = newJObject()
  if body != nil:
    body_600408 = body
  result = call_600407.call(nil, nil, nil, nil, body_600408)

var describeConformancePacks* = Call_DescribeConformancePacks_600394(
    name: "describeConformancePacks", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeConformancePacks",
    validator: validate_DescribeConformancePacks_600395, base: "/",
    url: url_DescribeConformancePacks_600396, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDeliveryChannelStatus_600409 = ref object of OpenApiRestCall_599368
proc url_DescribeDeliveryChannelStatus_600411(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDeliveryChannelStatus_600410(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600412 = header.getOrDefault("X-Amz-Date")
  valid_600412 = validateParameter(valid_600412, JString, required = false,
                                 default = nil)
  if valid_600412 != nil:
    section.add "X-Amz-Date", valid_600412
  var valid_600413 = header.getOrDefault("X-Amz-Security-Token")
  valid_600413 = validateParameter(valid_600413, JString, required = false,
                                 default = nil)
  if valid_600413 != nil:
    section.add "X-Amz-Security-Token", valid_600413
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600414 = header.getOrDefault("X-Amz-Target")
  valid_600414 = validateParameter(valid_600414, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeDeliveryChannelStatus"))
  if valid_600414 != nil:
    section.add "X-Amz-Target", valid_600414
  var valid_600415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600415 = validateParameter(valid_600415, JString, required = false,
                                 default = nil)
  if valid_600415 != nil:
    section.add "X-Amz-Content-Sha256", valid_600415
  var valid_600416 = header.getOrDefault("X-Amz-Algorithm")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "X-Amz-Algorithm", valid_600416
  var valid_600417 = header.getOrDefault("X-Amz-Signature")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "X-Amz-Signature", valid_600417
  var valid_600418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600418 = validateParameter(valid_600418, JString, required = false,
                                 default = nil)
  if valid_600418 != nil:
    section.add "X-Amz-SignedHeaders", valid_600418
  var valid_600419 = header.getOrDefault("X-Amz-Credential")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-Credential", valid_600419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600421: Call_DescribeDeliveryChannelStatus_600409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the current status of the specified delivery channel. If a delivery channel is not specified, this action returns the current status of all delivery channels associated with the account.</p> <note> <p>Currently, you can specify only one delivery channel per region in your account.</p> </note>
  ## 
  let valid = call_600421.validator(path, query, header, formData, body)
  let scheme = call_600421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600421.url(scheme.get, call_600421.host, call_600421.base,
                         call_600421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600421, url, valid)

proc call*(call_600422: Call_DescribeDeliveryChannelStatus_600409; body: JsonNode): Recallable =
  ## describeDeliveryChannelStatus
  ## <p>Returns the current status of the specified delivery channel. If a delivery channel is not specified, this action returns the current status of all delivery channels associated with the account.</p> <note> <p>Currently, you can specify only one delivery channel per region in your account.</p> </note>
  ##   body: JObject (required)
  var body_600423 = newJObject()
  if body != nil:
    body_600423 = body
  result = call_600422.call(nil, nil, nil, nil, body_600423)

var describeDeliveryChannelStatus* = Call_DescribeDeliveryChannelStatus_600409(
    name: "describeDeliveryChannelStatus", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeDeliveryChannelStatus",
    validator: validate_DescribeDeliveryChannelStatus_600410, base: "/",
    url: url_DescribeDeliveryChannelStatus_600411,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDeliveryChannels_600424 = ref object of OpenApiRestCall_599368
proc url_DescribeDeliveryChannels_600426(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDeliveryChannels_600425(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600427 = header.getOrDefault("X-Amz-Date")
  valid_600427 = validateParameter(valid_600427, JString, required = false,
                                 default = nil)
  if valid_600427 != nil:
    section.add "X-Amz-Date", valid_600427
  var valid_600428 = header.getOrDefault("X-Amz-Security-Token")
  valid_600428 = validateParameter(valid_600428, JString, required = false,
                                 default = nil)
  if valid_600428 != nil:
    section.add "X-Amz-Security-Token", valid_600428
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600429 = header.getOrDefault("X-Amz-Target")
  valid_600429 = validateParameter(valid_600429, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeDeliveryChannels"))
  if valid_600429 != nil:
    section.add "X-Amz-Target", valid_600429
  var valid_600430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600430 = validateParameter(valid_600430, JString, required = false,
                                 default = nil)
  if valid_600430 != nil:
    section.add "X-Amz-Content-Sha256", valid_600430
  var valid_600431 = header.getOrDefault("X-Amz-Algorithm")
  valid_600431 = validateParameter(valid_600431, JString, required = false,
                                 default = nil)
  if valid_600431 != nil:
    section.add "X-Amz-Algorithm", valid_600431
  var valid_600432 = header.getOrDefault("X-Amz-Signature")
  valid_600432 = validateParameter(valid_600432, JString, required = false,
                                 default = nil)
  if valid_600432 != nil:
    section.add "X-Amz-Signature", valid_600432
  var valid_600433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600433 = validateParameter(valid_600433, JString, required = false,
                                 default = nil)
  if valid_600433 != nil:
    section.add "X-Amz-SignedHeaders", valid_600433
  var valid_600434 = header.getOrDefault("X-Amz-Credential")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-Credential", valid_600434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600436: Call_DescribeDeliveryChannels_600424; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns details about the specified delivery channel. If a delivery channel is not specified, this action returns the details of all delivery channels associated with the account.</p> <note> <p>Currently, you can specify only one delivery channel per region in your account.</p> </note>
  ## 
  let valid = call_600436.validator(path, query, header, formData, body)
  let scheme = call_600436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600436.url(scheme.get, call_600436.host, call_600436.base,
                         call_600436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600436, url, valid)

proc call*(call_600437: Call_DescribeDeliveryChannels_600424; body: JsonNode): Recallable =
  ## describeDeliveryChannels
  ## <p>Returns details about the specified delivery channel. If a delivery channel is not specified, this action returns the details of all delivery channels associated with the account.</p> <note> <p>Currently, you can specify only one delivery channel per region in your account.</p> </note>
  ##   body: JObject (required)
  var body_600438 = newJObject()
  if body != nil:
    body_600438 = body
  result = call_600437.call(nil, nil, nil, nil, body_600438)

var describeDeliveryChannels* = Call_DescribeDeliveryChannels_600424(
    name: "describeDeliveryChannels", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeDeliveryChannels",
    validator: validate_DescribeDeliveryChannels_600425, base: "/",
    url: url_DescribeDeliveryChannels_600426, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrganizationConfigRuleStatuses_600439 = ref object of OpenApiRestCall_599368
proc url_DescribeOrganizationConfigRuleStatuses_600441(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeOrganizationConfigRuleStatuses_600440(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600442 = header.getOrDefault("X-Amz-Date")
  valid_600442 = validateParameter(valid_600442, JString, required = false,
                                 default = nil)
  if valid_600442 != nil:
    section.add "X-Amz-Date", valid_600442
  var valid_600443 = header.getOrDefault("X-Amz-Security-Token")
  valid_600443 = validateParameter(valid_600443, JString, required = false,
                                 default = nil)
  if valid_600443 != nil:
    section.add "X-Amz-Security-Token", valid_600443
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600444 = header.getOrDefault("X-Amz-Target")
  valid_600444 = validateParameter(valid_600444, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeOrganizationConfigRuleStatuses"))
  if valid_600444 != nil:
    section.add "X-Amz-Target", valid_600444
  var valid_600445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600445 = validateParameter(valid_600445, JString, required = false,
                                 default = nil)
  if valid_600445 != nil:
    section.add "X-Amz-Content-Sha256", valid_600445
  var valid_600446 = header.getOrDefault("X-Amz-Algorithm")
  valid_600446 = validateParameter(valid_600446, JString, required = false,
                                 default = nil)
  if valid_600446 != nil:
    section.add "X-Amz-Algorithm", valid_600446
  var valid_600447 = header.getOrDefault("X-Amz-Signature")
  valid_600447 = validateParameter(valid_600447, JString, required = false,
                                 default = nil)
  if valid_600447 != nil:
    section.add "X-Amz-Signature", valid_600447
  var valid_600448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600448 = validateParameter(valid_600448, JString, required = false,
                                 default = nil)
  if valid_600448 != nil:
    section.add "X-Amz-SignedHeaders", valid_600448
  var valid_600449 = header.getOrDefault("X-Amz-Credential")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "X-Amz-Credential", valid_600449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600451: Call_DescribeOrganizationConfigRuleStatuses_600439;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Provides organization config rule deployment status for an organization.</p> <note> <p>The status is not considered successful until organization config rule is successfully deployed in all the member accounts with an exception of excluded accounts.</p> <p>When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization config rule names. It is only applicable, when you request all the organization config rules.</p> <p>Only a master account can call this API.</p> </note>
  ## 
  let valid = call_600451.validator(path, query, header, formData, body)
  let scheme = call_600451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600451.url(scheme.get, call_600451.host, call_600451.base,
                         call_600451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600451, url, valid)

proc call*(call_600452: Call_DescribeOrganizationConfigRuleStatuses_600439;
          body: JsonNode): Recallable =
  ## describeOrganizationConfigRuleStatuses
  ## <p>Provides organization config rule deployment status for an organization.</p> <note> <p>The status is not considered successful until organization config rule is successfully deployed in all the member accounts with an exception of excluded accounts.</p> <p>When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization config rule names. It is only applicable, when you request all the organization config rules.</p> <p>Only a master account can call this API.</p> </note>
  ##   body: JObject (required)
  var body_600453 = newJObject()
  if body != nil:
    body_600453 = body
  result = call_600452.call(nil, nil, nil, nil, body_600453)

var describeOrganizationConfigRuleStatuses* = Call_DescribeOrganizationConfigRuleStatuses_600439(
    name: "describeOrganizationConfigRuleStatuses", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeOrganizationConfigRuleStatuses",
    validator: validate_DescribeOrganizationConfigRuleStatuses_600440, base: "/",
    url: url_DescribeOrganizationConfigRuleStatuses_600441,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrganizationConfigRules_600454 = ref object of OpenApiRestCall_599368
proc url_DescribeOrganizationConfigRules_600456(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeOrganizationConfigRules_600455(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600457 = header.getOrDefault("X-Amz-Date")
  valid_600457 = validateParameter(valid_600457, JString, required = false,
                                 default = nil)
  if valid_600457 != nil:
    section.add "X-Amz-Date", valid_600457
  var valid_600458 = header.getOrDefault("X-Amz-Security-Token")
  valid_600458 = validateParameter(valid_600458, JString, required = false,
                                 default = nil)
  if valid_600458 != nil:
    section.add "X-Amz-Security-Token", valid_600458
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600459 = header.getOrDefault("X-Amz-Target")
  valid_600459 = validateParameter(valid_600459, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeOrganizationConfigRules"))
  if valid_600459 != nil:
    section.add "X-Amz-Target", valid_600459
  var valid_600460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600460 = validateParameter(valid_600460, JString, required = false,
                                 default = nil)
  if valid_600460 != nil:
    section.add "X-Amz-Content-Sha256", valid_600460
  var valid_600461 = header.getOrDefault("X-Amz-Algorithm")
  valid_600461 = validateParameter(valid_600461, JString, required = false,
                                 default = nil)
  if valid_600461 != nil:
    section.add "X-Amz-Algorithm", valid_600461
  var valid_600462 = header.getOrDefault("X-Amz-Signature")
  valid_600462 = validateParameter(valid_600462, JString, required = false,
                                 default = nil)
  if valid_600462 != nil:
    section.add "X-Amz-Signature", valid_600462
  var valid_600463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600463 = validateParameter(valid_600463, JString, required = false,
                                 default = nil)
  if valid_600463 != nil:
    section.add "X-Amz-SignedHeaders", valid_600463
  var valid_600464 = header.getOrDefault("X-Amz-Credential")
  valid_600464 = validateParameter(valid_600464, JString, required = false,
                                 default = nil)
  if valid_600464 != nil:
    section.add "X-Amz-Credential", valid_600464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600466: Call_DescribeOrganizationConfigRules_600454;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of organization config rules.</p> <note> <p>When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization config rule names. It is only applicable, when you request all the organization config rules.</p> <p>Only a master account can call this API.</p> </note>
  ## 
  let valid = call_600466.validator(path, query, header, formData, body)
  let scheme = call_600466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600466.url(scheme.get, call_600466.host, call_600466.base,
                         call_600466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600466, url, valid)

proc call*(call_600467: Call_DescribeOrganizationConfigRules_600454; body: JsonNode): Recallable =
  ## describeOrganizationConfigRules
  ## <p>Returns a list of organization config rules.</p> <note> <p>When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization config rule names. It is only applicable, when you request all the organization config rules.</p> <p>Only a master account can call this API.</p> </note>
  ##   body: JObject (required)
  var body_600468 = newJObject()
  if body != nil:
    body_600468 = body
  result = call_600467.call(nil, nil, nil, nil, body_600468)

var describeOrganizationConfigRules* = Call_DescribeOrganizationConfigRules_600454(
    name: "describeOrganizationConfigRules", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeOrganizationConfigRules",
    validator: validate_DescribeOrganizationConfigRules_600455, base: "/",
    url: url_DescribeOrganizationConfigRules_600456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrganizationConformancePackStatuses_600469 = ref object of OpenApiRestCall_599368
proc url_DescribeOrganizationConformancePackStatuses_600471(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeOrganizationConformancePackStatuses_600470(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600472 = header.getOrDefault("X-Amz-Date")
  valid_600472 = validateParameter(valid_600472, JString, required = false,
                                 default = nil)
  if valid_600472 != nil:
    section.add "X-Amz-Date", valid_600472
  var valid_600473 = header.getOrDefault("X-Amz-Security-Token")
  valid_600473 = validateParameter(valid_600473, JString, required = false,
                                 default = nil)
  if valid_600473 != nil:
    section.add "X-Amz-Security-Token", valid_600473
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600474 = header.getOrDefault("X-Amz-Target")
  valid_600474 = validateParameter(valid_600474, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeOrganizationConformancePackStatuses"))
  if valid_600474 != nil:
    section.add "X-Amz-Target", valid_600474
  var valid_600475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600475 = validateParameter(valid_600475, JString, required = false,
                                 default = nil)
  if valid_600475 != nil:
    section.add "X-Amz-Content-Sha256", valid_600475
  var valid_600476 = header.getOrDefault("X-Amz-Algorithm")
  valid_600476 = validateParameter(valid_600476, JString, required = false,
                                 default = nil)
  if valid_600476 != nil:
    section.add "X-Amz-Algorithm", valid_600476
  var valid_600477 = header.getOrDefault("X-Amz-Signature")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "X-Amz-Signature", valid_600477
  var valid_600478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600478 = validateParameter(valid_600478, JString, required = false,
                                 default = nil)
  if valid_600478 != nil:
    section.add "X-Amz-SignedHeaders", valid_600478
  var valid_600479 = header.getOrDefault("X-Amz-Credential")
  valid_600479 = validateParameter(valid_600479, JString, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "X-Amz-Credential", valid_600479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600481: Call_DescribeOrganizationConformancePackStatuses_600469;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Provides organization conformance pack deployment status for an organization.</p> <note> <p>The status is not considered successful until organization conformance pack is successfully deployed in all the member accounts with an exception of excluded accounts.</p> <p>When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization conformance pack names. They are only applicable, when you request all the organization conformance packs.</p> <p>Only a master account can call this API.</p> </note>
  ## 
  let valid = call_600481.validator(path, query, header, formData, body)
  let scheme = call_600481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600481.url(scheme.get, call_600481.host, call_600481.base,
                         call_600481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600481, url, valid)

proc call*(call_600482: Call_DescribeOrganizationConformancePackStatuses_600469;
          body: JsonNode): Recallable =
  ## describeOrganizationConformancePackStatuses
  ## <p>Provides organization conformance pack deployment status for an organization.</p> <note> <p>The status is not considered successful until organization conformance pack is successfully deployed in all the member accounts with an exception of excluded accounts.</p> <p>When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization conformance pack names. They are only applicable, when you request all the organization conformance packs.</p> <p>Only a master account can call this API.</p> </note>
  ##   body: JObject (required)
  var body_600483 = newJObject()
  if body != nil:
    body_600483 = body
  result = call_600482.call(nil, nil, nil, nil, body_600483)

var describeOrganizationConformancePackStatuses* = Call_DescribeOrganizationConformancePackStatuses_600469(
    name: "describeOrganizationConformancePackStatuses",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeOrganizationConformancePackStatuses",
    validator: validate_DescribeOrganizationConformancePackStatuses_600470,
    base: "/", url: url_DescribeOrganizationConformancePackStatuses_600471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrganizationConformancePacks_600484 = ref object of OpenApiRestCall_599368
proc url_DescribeOrganizationConformancePacks_600486(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeOrganizationConformancePacks_600485(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600487 = header.getOrDefault("X-Amz-Date")
  valid_600487 = validateParameter(valid_600487, JString, required = false,
                                 default = nil)
  if valid_600487 != nil:
    section.add "X-Amz-Date", valid_600487
  var valid_600488 = header.getOrDefault("X-Amz-Security-Token")
  valid_600488 = validateParameter(valid_600488, JString, required = false,
                                 default = nil)
  if valid_600488 != nil:
    section.add "X-Amz-Security-Token", valid_600488
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600489 = header.getOrDefault("X-Amz-Target")
  valid_600489 = validateParameter(valid_600489, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeOrganizationConformancePacks"))
  if valid_600489 != nil:
    section.add "X-Amz-Target", valid_600489
  var valid_600490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600490 = validateParameter(valid_600490, JString, required = false,
                                 default = nil)
  if valid_600490 != nil:
    section.add "X-Amz-Content-Sha256", valid_600490
  var valid_600491 = header.getOrDefault("X-Amz-Algorithm")
  valid_600491 = validateParameter(valid_600491, JString, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "X-Amz-Algorithm", valid_600491
  var valid_600492 = header.getOrDefault("X-Amz-Signature")
  valid_600492 = validateParameter(valid_600492, JString, required = false,
                                 default = nil)
  if valid_600492 != nil:
    section.add "X-Amz-Signature", valid_600492
  var valid_600493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600493 = validateParameter(valid_600493, JString, required = false,
                                 default = nil)
  if valid_600493 != nil:
    section.add "X-Amz-SignedHeaders", valid_600493
  var valid_600494 = header.getOrDefault("X-Amz-Credential")
  valid_600494 = validateParameter(valid_600494, JString, required = false,
                                 default = nil)
  if valid_600494 != nil:
    section.add "X-Amz-Credential", valid_600494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600496: Call_DescribeOrganizationConformancePacks_600484;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of organization conformance packs.</p> <note> <p>When you specify the limit and the next token, you receive a paginated response. </p> <p>Limit and next token are not applicable if you specify organization conformance packs names. They are only applicable, when you request all the organization conformance packs. </p> <p>Only a master account can call this API.</p> </note>
  ## 
  let valid = call_600496.validator(path, query, header, formData, body)
  let scheme = call_600496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600496.url(scheme.get, call_600496.host, call_600496.base,
                         call_600496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600496, url, valid)

proc call*(call_600497: Call_DescribeOrganizationConformancePacks_600484;
          body: JsonNode): Recallable =
  ## describeOrganizationConformancePacks
  ## <p>Returns a list of organization conformance packs.</p> <note> <p>When you specify the limit and the next token, you receive a paginated response. </p> <p>Limit and next token are not applicable if you specify organization conformance packs names. They are only applicable, when you request all the organization conformance packs. </p> <p>Only a master account can call this API.</p> </note>
  ##   body: JObject (required)
  var body_600498 = newJObject()
  if body != nil:
    body_600498 = body
  result = call_600497.call(nil, nil, nil, nil, body_600498)

var describeOrganizationConformancePacks* = Call_DescribeOrganizationConformancePacks_600484(
    name: "describeOrganizationConformancePacks", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeOrganizationConformancePacks",
    validator: validate_DescribeOrganizationConformancePacks_600485, base: "/",
    url: url_DescribeOrganizationConformancePacks_600486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePendingAggregationRequests_600499 = ref object of OpenApiRestCall_599368
proc url_DescribePendingAggregationRequests_600501(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePendingAggregationRequests_600500(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600502 = header.getOrDefault("X-Amz-Date")
  valid_600502 = validateParameter(valid_600502, JString, required = false,
                                 default = nil)
  if valid_600502 != nil:
    section.add "X-Amz-Date", valid_600502
  var valid_600503 = header.getOrDefault("X-Amz-Security-Token")
  valid_600503 = validateParameter(valid_600503, JString, required = false,
                                 default = nil)
  if valid_600503 != nil:
    section.add "X-Amz-Security-Token", valid_600503
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600504 = header.getOrDefault("X-Amz-Target")
  valid_600504 = validateParameter(valid_600504, JString, required = true, default = newJString(
      "StarlingDoveService.DescribePendingAggregationRequests"))
  if valid_600504 != nil:
    section.add "X-Amz-Target", valid_600504
  var valid_600505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600505 = validateParameter(valid_600505, JString, required = false,
                                 default = nil)
  if valid_600505 != nil:
    section.add "X-Amz-Content-Sha256", valid_600505
  var valid_600506 = header.getOrDefault("X-Amz-Algorithm")
  valid_600506 = validateParameter(valid_600506, JString, required = false,
                                 default = nil)
  if valid_600506 != nil:
    section.add "X-Amz-Algorithm", valid_600506
  var valid_600507 = header.getOrDefault("X-Amz-Signature")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "X-Amz-Signature", valid_600507
  var valid_600508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600508 = validateParameter(valid_600508, JString, required = false,
                                 default = nil)
  if valid_600508 != nil:
    section.add "X-Amz-SignedHeaders", valid_600508
  var valid_600509 = header.getOrDefault("X-Amz-Credential")
  valid_600509 = validateParameter(valid_600509, JString, required = false,
                                 default = nil)
  if valid_600509 != nil:
    section.add "X-Amz-Credential", valid_600509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600511: Call_DescribePendingAggregationRequests_600499;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of all pending aggregation requests.
  ## 
  let valid = call_600511.validator(path, query, header, formData, body)
  let scheme = call_600511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600511.url(scheme.get, call_600511.host, call_600511.base,
                         call_600511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600511, url, valid)

proc call*(call_600512: Call_DescribePendingAggregationRequests_600499;
          body: JsonNode): Recallable =
  ## describePendingAggregationRequests
  ## Returns a list of all pending aggregation requests.
  ##   body: JObject (required)
  var body_600513 = newJObject()
  if body != nil:
    body_600513 = body
  result = call_600512.call(nil, nil, nil, nil, body_600513)

var describePendingAggregationRequests* = Call_DescribePendingAggregationRequests_600499(
    name: "describePendingAggregationRequests", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribePendingAggregationRequests",
    validator: validate_DescribePendingAggregationRequests_600500, base: "/",
    url: url_DescribePendingAggregationRequests_600501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRemediationConfigurations_600514 = ref object of OpenApiRestCall_599368
proc url_DescribeRemediationConfigurations_600516(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRemediationConfigurations_600515(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600517 = header.getOrDefault("X-Amz-Date")
  valid_600517 = validateParameter(valid_600517, JString, required = false,
                                 default = nil)
  if valid_600517 != nil:
    section.add "X-Amz-Date", valid_600517
  var valid_600518 = header.getOrDefault("X-Amz-Security-Token")
  valid_600518 = validateParameter(valid_600518, JString, required = false,
                                 default = nil)
  if valid_600518 != nil:
    section.add "X-Amz-Security-Token", valid_600518
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600519 = header.getOrDefault("X-Amz-Target")
  valid_600519 = validateParameter(valid_600519, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeRemediationConfigurations"))
  if valid_600519 != nil:
    section.add "X-Amz-Target", valid_600519
  var valid_600520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600520 = validateParameter(valid_600520, JString, required = false,
                                 default = nil)
  if valid_600520 != nil:
    section.add "X-Amz-Content-Sha256", valid_600520
  var valid_600521 = header.getOrDefault("X-Amz-Algorithm")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "X-Amz-Algorithm", valid_600521
  var valid_600522 = header.getOrDefault("X-Amz-Signature")
  valid_600522 = validateParameter(valid_600522, JString, required = false,
                                 default = nil)
  if valid_600522 != nil:
    section.add "X-Amz-Signature", valid_600522
  var valid_600523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600523 = validateParameter(valid_600523, JString, required = false,
                                 default = nil)
  if valid_600523 != nil:
    section.add "X-Amz-SignedHeaders", valid_600523
  var valid_600524 = header.getOrDefault("X-Amz-Credential")
  valid_600524 = validateParameter(valid_600524, JString, required = false,
                                 default = nil)
  if valid_600524 != nil:
    section.add "X-Amz-Credential", valid_600524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600526: Call_DescribeRemediationConfigurations_600514;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the details of one or more remediation configurations.
  ## 
  let valid = call_600526.validator(path, query, header, formData, body)
  let scheme = call_600526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600526.url(scheme.get, call_600526.host, call_600526.base,
                         call_600526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600526, url, valid)

proc call*(call_600527: Call_DescribeRemediationConfigurations_600514;
          body: JsonNode): Recallable =
  ## describeRemediationConfigurations
  ## Returns the details of one or more remediation configurations.
  ##   body: JObject (required)
  var body_600528 = newJObject()
  if body != nil:
    body_600528 = body
  result = call_600527.call(nil, nil, nil, nil, body_600528)

var describeRemediationConfigurations* = Call_DescribeRemediationConfigurations_600514(
    name: "describeRemediationConfigurations", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeRemediationConfigurations",
    validator: validate_DescribeRemediationConfigurations_600515, base: "/",
    url: url_DescribeRemediationConfigurations_600516,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRemediationExceptions_600529 = ref object of OpenApiRestCall_599368
proc url_DescribeRemediationExceptions_600531(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRemediationExceptions_600530(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600532 = query.getOrDefault("Limit")
  valid_600532 = validateParameter(valid_600532, JString, required = false,
                                 default = nil)
  if valid_600532 != nil:
    section.add "Limit", valid_600532
  var valid_600533 = query.getOrDefault("NextToken")
  valid_600533 = validateParameter(valid_600533, JString, required = false,
                                 default = nil)
  if valid_600533 != nil:
    section.add "NextToken", valid_600533
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
  var valid_600534 = header.getOrDefault("X-Amz-Date")
  valid_600534 = validateParameter(valid_600534, JString, required = false,
                                 default = nil)
  if valid_600534 != nil:
    section.add "X-Amz-Date", valid_600534
  var valid_600535 = header.getOrDefault("X-Amz-Security-Token")
  valid_600535 = validateParameter(valid_600535, JString, required = false,
                                 default = nil)
  if valid_600535 != nil:
    section.add "X-Amz-Security-Token", valid_600535
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600536 = header.getOrDefault("X-Amz-Target")
  valid_600536 = validateParameter(valid_600536, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeRemediationExceptions"))
  if valid_600536 != nil:
    section.add "X-Amz-Target", valid_600536
  var valid_600537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600537 = validateParameter(valid_600537, JString, required = false,
                                 default = nil)
  if valid_600537 != nil:
    section.add "X-Amz-Content-Sha256", valid_600537
  var valid_600538 = header.getOrDefault("X-Amz-Algorithm")
  valid_600538 = validateParameter(valid_600538, JString, required = false,
                                 default = nil)
  if valid_600538 != nil:
    section.add "X-Amz-Algorithm", valid_600538
  var valid_600539 = header.getOrDefault("X-Amz-Signature")
  valid_600539 = validateParameter(valid_600539, JString, required = false,
                                 default = nil)
  if valid_600539 != nil:
    section.add "X-Amz-Signature", valid_600539
  var valid_600540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600540 = validateParameter(valid_600540, JString, required = false,
                                 default = nil)
  if valid_600540 != nil:
    section.add "X-Amz-SignedHeaders", valid_600540
  var valid_600541 = header.getOrDefault("X-Amz-Credential")
  valid_600541 = validateParameter(valid_600541, JString, required = false,
                                 default = nil)
  if valid_600541 != nil:
    section.add "X-Amz-Credential", valid_600541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600543: Call_DescribeRemediationExceptions_600529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the details of one or more remediation exceptions. A detailed view of a remediation exception for a set of resources that includes an explanation of an exception and the time when the exception will be deleted. When you specify the limit and the next token, you receive a paginated response. </p> <note> <p>When you specify the limit and the next token, you receive a paginated response. </p> <p>Limit and next token are not applicable if you request resources in batch. It is only applicable, when you request all resources.</p> </note>
  ## 
  let valid = call_600543.validator(path, query, header, formData, body)
  let scheme = call_600543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600543.url(scheme.get, call_600543.host, call_600543.base,
                         call_600543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600543, url, valid)

proc call*(call_600544: Call_DescribeRemediationExceptions_600529; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## describeRemediationExceptions
  ## <p>Returns the details of one or more remediation exceptions. A detailed view of a remediation exception for a set of resources that includes an explanation of an exception and the time when the exception will be deleted. When you specify the limit and the next token, you receive a paginated response. </p> <note> <p>When you specify the limit and the next token, you receive a paginated response. </p> <p>Limit and next token are not applicable if you request resources in batch. It is only applicable, when you request all resources.</p> </note>
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600545 = newJObject()
  var body_600546 = newJObject()
  add(query_600545, "Limit", newJString(Limit))
  add(query_600545, "NextToken", newJString(NextToken))
  if body != nil:
    body_600546 = body
  result = call_600544.call(nil, query_600545, nil, nil, body_600546)

var describeRemediationExceptions* = Call_DescribeRemediationExceptions_600529(
    name: "describeRemediationExceptions", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeRemediationExceptions",
    validator: validate_DescribeRemediationExceptions_600530, base: "/",
    url: url_DescribeRemediationExceptions_600531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRemediationExecutionStatus_600548 = ref object of OpenApiRestCall_599368
proc url_DescribeRemediationExecutionStatus_600550(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRemediationExecutionStatus_600549(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600551 = query.getOrDefault("Limit")
  valid_600551 = validateParameter(valid_600551, JString, required = false,
                                 default = nil)
  if valid_600551 != nil:
    section.add "Limit", valid_600551
  var valid_600552 = query.getOrDefault("NextToken")
  valid_600552 = validateParameter(valid_600552, JString, required = false,
                                 default = nil)
  if valid_600552 != nil:
    section.add "NextToken", valid_600552
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
  var valid_600553 = header.getOrDefault("X-Amz-Date")
  valid_600553 = validateParameter(valid_600553, JString, required = false,
                                 default = nil)
  if valid_600553 != nil:
    section.add "X-Amz-Date", valid_600553
  var valid_600554 = header.getOrDefault("X-Amz-Security-Token")
  valid_600554 = validateParameter(valid_600554, JString, required = false,
                                 default = nil)
  if valid_600554 != nil:
    section.add "X-Amz-Security-Token", valid_600554
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600555 = header.getOrDefault("X-Amz-Target")
  valid_600555 = validateParameter(valid_600555, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeRemediationExecutionStatus"))
  if valid_600555 != nil:
    section.add "X-Amz-Target", valid_600555
  var valid_600556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600556 = validateParameter(valid_600556, JString, required = false,
                                 default = nil)
  if valid_600556 != nil:
    section.add "X-Amz-Content-Sha256", valid_600556
  var valid_600557 = header.getOrDefault("X-Amz-Algorithm")
  valid_600557 = validateParameter(valid_600557, JString, required = false,
                                 default = nil)
  if valid_600557 != nil:
    section.add "X-Amz-Algorithm", valid_600557
  var valid_600558 = header.getOrDefault("X-Amz-Signature")
  valid_600558 = validateParameter(valid_600558, JString, required = false,
                                 default = nil)
  if valid_600558 != nil:
    section.add "X-Amz-Signature", valid_600558
  var valid_600559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600559 = validateParameter(valid_600559, JString, required = false,
                                 default = nil)
  if valid_600559 != nil:
    section.add "X-Amz-SignedHeaders", valid_600559
  var valid_600560 = header.getOrDefault("X-Amz-Credential")
  valid_600560 = validateParameter(valid_600560, JString, required = false,
                                 default = nil)
  if valid_600560 != nil:
    section.add "X-Amz-Credential", valid_600560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600562: Call_DescribeRemediationExecutionStatus_600548;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Provides a detailed view of a Remediation Execution for a set of resources including state, timestamps for when steps for the remediation execution occur, and any error messages for steps that have failed. When you specify the limit and the next token, you receive a paginated response.
  ## 
  let valid = call_600562.validator(path, query, header, formData, body)
  let scheme = call_600562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600562.url(scheme.get, call_600562.host, call_600562.base,
                         call_600562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600562, url, valid)

proc call*(call_600563: Call_DescribeRemediationExecutionStatus_600548;
          body: JsonNode; Limit: string = ""; NextToken: string = ""): Recallable =
  ## describeRemediationExecutionStatus
  ## Provides a detailed view of a Remediation Execution for a set of resources including state, timestamps for when steps for the remediation execution occur, and any error messages for steps that have failed. When you specify the limit and the next token, you receive a paginated response.
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600564 = newJObject()
  var body_600565 = newJObject()
  add(query_600564, "Limit", newJString(Limit))
  add(query_600564, "NextToken", newJString(NextToken))
  if body != nil:
    body_600565 = body
  result = call_600563.call(nil, query_600564, nil, nil, body_600565)

var describeRemediationExecutionStatus* = Call_DescribeRemediationExecutionStatus_600548(
    name: "describeRemediationExecutionStatus", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeRemediationExecutionStatus",
    validator: validate_DescribeRemediationExecutionStatus_600549, base: "/",
    url: url_DescribeRemediationExecutionStatus_600550,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRetentionConfigurations_600566 = ref object of OpenApiRestCall_599368
proc url_DescribeRetentionConfigurations_600568(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRetentionConfigurations_600567(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600569 = header.getOrDefault("X-Amz-Date")
  valid_600569 = validateParameter(valid_600569, JString, required = false,
                                 default = nil)
  if valid_600569 != nil:
    section.add "X-Amz-Date", valid_600569
  var valid_600570 = header.getOrDefault("X-Amz-Security-Token")
  valid_600570 = validateParameter(valid_600570, JString, required = false,
                                 default = nil)
  if valid_600570 != nil:
    section.add "X-Amz-Security-Token", valid_600570
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600571 = header.getOrDefault("X-Amz-Target")
  valid_600571 = validateParameter(valid_600571, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeRetentionConfigurations"))
  if valid_600571 != nil:
    section.add "X-Amz-Target", valid_600571
  var valid_600572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600572 = validateParameter(valid_600572, JString, required = false,
                                 default = nil)
  if valid_600572 != nil:
    section.add "X-Amz-Content-Sha256", valid_600572
  var valid_600573 = header.getOrDefault("X-Amz-Algorithm")
  valid_600573 = validateParameter(valid_600573, JString, required = false,
                                 default = nil)
  if valid_600573 != nil:
    section.add "X-Amz-Algorithm", valid_600573
  var valid_600574 = header.getOrDefault("X-Amz-Signature")
  valid_600574 = validateParameter(valid_600574, JString, required = false,
                                 default = nil)
  if valid_600574 != nil:
    section.add "X-Amz-Signature", valid_600574
  var valid_600575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600575 = validateParameter(valid_600575, JString, required = false,
                                 default = nil)
  if valid_600575 != nil:
    section.add "X-Amz-SignedHeaders", valid_600575
  var valid_600576 = header.getOrDefault("X-Amz-Credential")
  valid_600576 = validateParameter(valid_600576, JString, required = false,
                                 default = nil)
  if valid_600576 != nil:
    section.add "X-Amz-Credential", valid_600576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600578: Call_DescribeRetentionConfigurations_600566;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the details of one or more retention configurations. If the retention configuration name is not specified, this action returns the details for all the retention configurations for that account.</p> <note> <p>Currently, AWS Config supports only one retention configuration per region in your account.</p> </note>
  ## 
  let valid = call_600578.validator(path, query, header, formData, body)
  let scheme = call_600578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600578.url(scheme.get, call_600578.host, call_600578.base,
                         call_600578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600578, url, valid)

proc call*(call_600579: Call_DescribeRetentionConfigurations_600566; body: JsonNode): Recallable =
  ## describeRetentionConfigurations
  ## <p>Returns the details of one or more retention configurations. If the retention configuration name is not specified, this action returns the details for all the retention configurations for that account.</p> <note> <p>Currently, AWS Config supports only one retention configuration per region in your account.</p> </note>
  ##   body: JObject (required)
  var body_600580 = newJObject()
  if body != nil:
    body_600580 = body
  result = call_600579.call(nil, nil, nil, nil, body_600580)

var describeRetentionConfigurations* = Call_DescribeRetentionConfigurations_600566(
    name: "describeRetentionConfigurations", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeRetentionConfigurations",
    validator: validate_DescribeRetentionConfigurations_600567, base: "/",
    url: url_DescribeRetentionConfigurations_600568,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAggregateComplianceDetailsByConfigRule_600581 = ref object of OpenApiRestCall_599368
proc url_GetAggregateComplianceDetailsByConfigRule_600583(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAggregateComplianceDetailsByConfigRule_600582(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600584 = header.getOrDefault("X-Amz-Date")
  valid_600584 = validateParameter(valid_600584, JString, required = false,
                                 default = nil)
  if valid_600584 != nil:
    section.add "X-Amz-Date", valid_600584
  var valid_600585 = header.getOrDefault("X-Amz-Security-Token")
  valid_600585 = validateParameter(valid_600585, JString, required = false,
                                 default = nil)
  if valid_600585 != nil:
    section.add "X-Amz-Security-Token", valid_600585
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600586 = header.getOrDefault("X-Amz-Target")
  valid_600586 = validateParameter(valid_600586, JString, required = true, default = newJString(
      "StarlingDoveService.GetAggregateComplianceDetailsByConfigRule"))
  if valid_600586 != nil:
    section.add "X-Amz-Target", valid_600586
  var valid_600587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600587 = validateParameter(valid_600587, JString, required = false,
                                 default = nil)
  if valid_600587 != nil:
    section.add "X-Amz-Content-Sha256", valid_600587
  var valid_600588 = header.getOrDefault("X-Amz-Algorithm")
  valid_600588 = validateParameter(valid_600588, JString, required = false,
                                 default = nil)
  if valid_600588 != nil:
    section.add "X-Amz-Algorithm", valid_600588
  var valid_600589 = header.getOrDefault("X-Amz-Signature")
  valid_600589 = validateParameter(valid_600589, JString, required = false,
                                 default = nil)
  if valid_600589 != nil:
    section.add "X-Amz-Signature", valid_600589
  var valid_600590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600590 = validateParameter(valid_600590, JString, required = false,
                                 default = nil)
  if valid_600590 != nil:
    section.add "X-Amz-SignedHeaders", valid_600590
  var valid_600591 = header.getOrDefault("X-Amz-Credential")
  valid_600591 = validateParameter(valid_600591, JString, required = false,
                                 default = nil)
  if valid_600591 != nil:
    section.add "X-Amz-Credential", valid_600591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600593: Call_GetAggregateComplianceDetailsByConfigRule_600581;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the evaluation results for the specified AWS Config rule for a specific resource in a rule. The results indicate which AWS resources were evaluated by the rule, when each resource was last evaluated, and whether each resource complies with the rule. </p> <note> <p>The results can return an empty result page. But if you have a <code>nextToken</code>, the results are displayed on the next page.</p> </note>
  ## 
  let valid = call_600593.validator(path, query, header, formData, body)
  let scheme = call_600593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600593.url(scheme.get, call_600593.host, call_600593.base,
                         call_600593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600593, url, valid)

proc call*(call_600594: Call_GetAggregateComplianceDetailsByConfigRule_600581;
          body: JsonNode): Recallable =
  ## getAggregateComplianceDetailsByConfigRule
  ## <p>Returns the evaluation results for the specified AWS Config rule for a specific resource in a rule. The results indicate which AWS resources were evaluated by the rule, when each resource was last evaluated, and whether each resource complies with the rule. </p> <note> <p>The results can return an empty result page. But if you have a <code>nextToken</code>, the results are displayed on the next page.</p> </note>
  ##   body: JObject (required)
  var body_600595 = newJObject()
  if body != nil:
    body_600595 = body
  result = call_600594.call(nil, nil, nil, nil, body_600595)

var getAggregateComplianceDetailsByConfigRule* = Call_GetAggregateComplianceDetailsByConfigRule_600581(
    name: "getAggregateComplianceDetailsByConfigRule", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetAggregateComplianceDetailsByConfigRule",
    validator: validate_GetAggregateComplianceDetailsByConfigRule_600582,
    base: "/", url: url_GetAggregateComplianceDetailsByConfigRule_600583,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAggregateConfigRuleComplianceSummary_600596 = ref object of OpenApiRestCall_599368
proc url_GetAggregateConfigRuleComplianceSummary_600598(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAggregateConfigRuleComplianceSummary_600597(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600599 = header.getOrDefault("X-Amz-Date")
  valid_600599 = validateParameter(valid_600599, JString, required = false,
                                 default = nil)
  if valid_600599 != nil:
    section.add "X-Amz-Date", valid_600599
  var valid_600600 = header.getOrDefault("X-Amz-Security-Token")
  valid_600600 = validateParameter(valid_600600, JString, required = false,
                                 default = nil)
  if valid_600600 != nil:
    section.add "X-Amz-Security-Token", valid_600600
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600601 = header.getOrDefault("X-Amz-Target")
  valid_600601 = validateParameter(valid_600601, JString, required = true, default = newJString(
      "StarlingDoveService.GetAggregateConfigRuleComplianceSummary"))
  if valid_600601 != nil:
    section.add "X-Amz-Target", valid_600601
  var valid_600602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600602 = validateParameter(valid_600602, JString, required = false,
                                 default = nil)
  if valid_600602 != nil:
    section.add "X-Amz-Content-Sha256", valid_600602
  var valid_600603 = header.getOrDefault("X-Amz-Algorithm")
  valid_600603 = validateParameter(valid_600603, JString, required = false,
                                 default = nil)
  if valid_600603 != nil:
    section.add "X-Amz-Algorithm", valid_600603
  var valid_600604 = header.getOrDefault("X-Amz-Signature")
  valid_600604 = validateParameter(valid_600604, JString, required = false,
                                 default = nil)
  if valid_600604 != nil:
    section.add "X-Amz-Signature", valid_600604
  var valid_600605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600605 = validateParameter(valid_600605, JString, required = false,
                                 default = nil)
  if valid_600605 != nil:
    section.add "X-Amz-SignedHeaders", valid_600605
  var valid_600606 = header.getOrDefault("X-Amz-Credential")
  valid_600606 = validateParameter(valid_600606, JString, required = false,
                                 default = nil)
  if valid_600606 != nil:
    section.add "X-Amz-Credential", valid_600606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600608: Call_GetAggregateConfigRuleComplianceSummary_600596;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the number of compliant and noncompliant rules for one or more accounts and regions in an aggregator.</p> <note> <p>The results can return an empty result page, but if you have a nextToken, the results are displayed on the next page.</p> </note>
  ## 
  let valid = call_600608.validator(path, query, header, formData, body)
  let scheme = call_600608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600608.url(scheme.get, call_600608.host, call_600608.base,
                         call_600608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600608, url, valid)

proc call*(call_600609: Call_GetAggregateConfigRuleComplianceSummary_600596;
          body: JsonNode): Recallable =
  ## getAggregateConfigRuleComplianceSummary
  ## <p>Returns the number of compliant and noncompliant rules for one or more accounts and regions in an aggregator.</p> <note> <p>The results can return an empty result page, but if you have a nextToken, the results are displayed on the next page.</p> </note>
  ##   body: JObject (required)
  var body_600610 = newJObject()
  if body != nil:
    body_600610 = body
  result = call_600609.call(nil, nil, nil, nil, body_600610)

var getAggregateConfigRuleComplianceSummary* = Call_GetAggregateConfigRuleComplianceSummary_600596(
    name: "getAggregateConfigRuleComplianceSummary", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetAggregateConfigRuleComplianceSummary",
    validator: validate_GetAggregateConfigRuleComplianceSummary_600597, base: "/",
    url: url_GetAggregateConfigRuleComplianceSummary_600598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAggregateDiscoveredResourceCounts_600611 = ref object of OpenApiRestCall_599368
proc url_GetAggregateDiscoveredResourceCounts_600613(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAggregateDiscoveredResourceCounts_600612(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600614 = header.getOrDefault("X-Amz-Date")
  valid_600614 = validateParameter(valid_600614, JString, required = false,
                                 default = nil)
  if valid_600614 != nil:
    section.add "X-Amz-Date", valid_600614
  var valid_600615 = header.getOrDefault("X-Amz-Security-Token")
  valid_600615 = validateParameter(valid_600615, JString, required = false,
                                 default = nil)
  if valid_600615 != nil:
    section.add "X-Amz-Security-Token", valid_600615
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600616 = header.getOrDefault("X-Amz-Target")
  valid_600616 = validateParameter(valid_600616, JString, required = true, default = newJString(
      "StarlingDoveService.GetAggregateDiscoveredResourceCounts"))
  if valid_600616 != nil:
    section.add "X-Amz-Target", valid_600616
  var valid_600617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600617 = validateParameter(valid_600617, JString, required = false,
                                 default = nil)
  if valid_600617 != nil:
    section.add "X-Amz-Content-Sha256", valid_600617
  var valid_600618 = header.getOrDefault("X-Amz-Algorithm")
  valid_600618 = validateParameter(valid_600618, JString, required = false,
                                 default = nil)
  if valid_600618 != nil:
    section.add "X-Amz-Algorithm", valid_600618
  var valid_600619 = header.getOrDefault("X-Amz-Signature")
  valid_600619 = validateParameter(valid_600619, JString, required = false,
                                 default = nil)
  if valid_600619 != nil:
    section.add "X-Amz-Signature", valid_600619
  var valid_600620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600620 = validateParameter(valid_600620, JString, required = false,
                                 default = nil)
  if valid_600620 != nil:
    section.add "X-Amz-SignedHeaders", valid_600620
  var valid_600621 = header.getOrDefault("X-Amz-Credential")
  valid_600621 = validateParameter(valid_600621, JString, required = false,
                                 default = nil)
  if valid_600621 != nil:
    section.add "X-Amz-Credential", valid_600621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600623: Call_GetAggregateDiscoveredResourceCounts_600611;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the resource counts across accounts and regions that are present in your AWS Config aggregator. You can request the resource counts by providing filters and GroupByKey.</p> <p>For example, if the input contains accountID 12345678910 and region us-east-1 in filters, the API returns the count of resources in account ID 12345678910 and region us-east-1. If the input contains ACCOUNT_ID as a GroupByKey, the API returns resource counts for all source accounts that are present in your aggregator.</p>
  ## 
  let valid = call_600623.validator(path, query, header, formData, body)
  let scheme = call_600623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600623.url(scheme.get, call_600623.host, call_600623.base,
                         call_600623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600623, url, valid)

proc call*(call_600624: Call_GetAggregateDiscoveredResourceCounts_600611;
          body: JsonNode): Recallable =
  ## getAggregateDiscoveredResourceCounts
  ## <p>Returns the resource counts across accounts and regions that are present in your AWS Config aggregator. You can request the resource counts by providing filters and GroupByKey.</p> <p>For example, if the input contains accountID 12345678910 and region us-east-1 in filters, the API returns the count of resources in account ID 12345678910 and region us-east-1. If the input contains ACCOUNT_ID as a GroupByKey, the API returns resource counts for all source accounts that are present in your aggregator.</p>
  ##   body: JObject (required)
  var body_600625 = newJObject()
  if body != nil:
    body_600625 = body
  result = call_600624.call(nil, nil, nil, nil, body_600625)

var getAggregateDiscoveredResourceCounts* = Call_GetAggregateDiscoveredResourceCounts_600611(
    name: "getAggregateDiscoveredResourceCounts", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetAggregateDiscoveredResourceCounts",
    validator: validate_GetAggregateDiscoveredResourceCounts_600612, base: "/",
    url: url_GetAggregateDiscoveredResourceCounts_600613,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAggregateResourceConfig_600626 = ref object of OpenApiRestCall_599368
proc url_GetAggregateResourceConfig_600628(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAggregateResourceConfig_600627(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600629 = header.getOrDefault("X-Amz-Date")
  valid_600629 = validateParameter(valid_600629, JString, required = false,
                                 default = nil)
  if valid_600629 != nil:
    section.add "X-Amz-Date", valid_600629
  var valid_600630 = header.getOrDefault("X-Amz-Security-Token")
  valid_600630 = validateParameter(valid_600630, JString, required = false,
                                 default = nil)
  if valid_600630 != nil:
    section.add "X-Amz-Security-Token", valid_600630
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600631 = header.getOrDefault("X-Amz-Target")
  valid_600631 = validateParameter(valid_600631, JString, required = true, default = newJString(
      "StarlingDoveService.GetAggregateResourceConfig"))
  if valid_600631 != nil:
    section.add "X-Amz-Target", valid_600631
  var valid_600632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600632 = validateParameter(valid_600632, JString, required = false,
                                 default = nil)
  if valid_600632 != nil:
    section.add "X-Amz-Content-Sha256", valid_600632
  var valid_600633 = header.getOrDefault("X-Amz-Algorithm")
  valid_600633 = validateParameter(valid_600633, JString, required = false,
                                 default = nil)
  if valid_600633 != nil:
    section.add "X-Amz-Algorithm", valid_600633
  var valid_600634 = header.getOrDefault("X-Amz-Signature")
  valid_600634 = validateParameter(valid_600634, JString, required = false,
                                 default = nil)
  if valid_600634 != nil:
    section.add "X-Amz-Signature", valid_600634
  var valid_600635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600635 = validateParameter(valid_600635, JString, required = false,
                                 default = nil)
  if valid_600635 != nil:
    section.add "X-Amz-SignedHeaders", valid_600635
  var valid_600636 = header.getOrDefault("X-Amz-Credential")
  valid_600636 = validateParameter(valid_600636, JString, required = false,
                                 default = nil)
  if valid_600636 != nil:
    section.add "X-Amz-Credential", valid_600636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600638: Call_GetAggregateResourceConfig_600626; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns configuration item that is aggregated for your specific resource in a specific source account and region.
  ## 
  let valid = call_600638.validator(path, query, header, formData, body)
  let scheme = call_600638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600638.url(scheme.get, call_600638.host, call_600638.base,
                         call_600638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600638, url, valid)

proc call*(call_600639: Call_GetAggregateResourceConfig_600626; body: JsonNode): Recallable =
  ## getAggregateResourceConfig
  ## Returns configuration item that is aggregated for your specific resource in a specific source account and region.
  ##   body: JObject (required)
  var body_600640 = newJObject()
  if body != nil:
    body_600640 = body
  result = call_600639.call(nil, nil, nil, nil, body_600640)

var getAggregateResourceConfig* = Call_GetAggregateResourceConfig_600626(
    name: "getAggregateResourceConfig", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.GetAggregateResourceConfig",
    validator: validate_GetAggregateResourceConfig_600627, base: "/",
    url: url_GetAggregateResourceConfig_600628,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComplianceDetailsByConfigRule_600641 = ref object of OpenApiRestCall_599368
proc url_GetComplianceDetailsByConfigRule_600643(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComplianceDetailsByConfigRule_600642(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600644 = header.getOrDefault("X-Amz-Date")
  valid_600644 = validateParameter(valid_600644, JString, required = false,
                                 default = nil)
  if valid_600644 != nil:
    section.add "X-Amz-Date", valid_600644
  var valid_600645 = header.getOrDefault("X-Amz-Security-Token")
  valid_600645 = validateParameter(valid_600645, JString, required = false,
                                 default = nil)
  if valid_600645 != nil:
    section.add "X-Amz-Security-Token", valid_600645
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600646 = header.getOrDefault("X-Amz-Target")
  valid_600646 = validateParameter(valid_600646, JString, required = true, default = newJString(
      "StarlingDoveService.GetComplianceDetailsByConfigRule"))
  if valid_600646 != nil:
    section.add "X-Amz-Target", valid_600646
  var valid_600647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600647 = validateParameter(valid_600647, JString, required = false,
                                 default = nil)
  if valid_600647 != nil:
    section.add "X-Amz-Content-Sha256", valid_600647
  var valid_600648 = header.getOrDefault("X-Amz-Algorithm")
  valid_600648 = validateParameter(valid_600648, JString, required = false,
                                 default = nil)
  if valid_600648 != nil:
    section.add "X-Amz-Algorithm", valid_600648
  var valid_600649 = header.getOrDefault("X-Amz-Signature")
  valid_600649 = validateParameter(valid_600649, JString, required = false,
                                 default = nil)
  if valid_600649 != nil:
    section.add "X-Amz-Signature", valid_600649
  var valid_600650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600650 = validateParameter(valid_600650, JString, required = false,
                                 default = nil)
  if valid_600650 != nil:
    section.add "X-Amz-SignedHeaders", valid_600650
  var valid_600651 = header.getOrDefault("X-Amz-Credential")
  valid_600651 = validateParameter(valid_600651, JString, required = false,
                                 default = nil)
  if valid_600651 != nil:
    section.add "X-Amz-Credential", valid_600651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600653: Call_GetComplianceDetailsByConfigRule_600641;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the evaluation results for the specified AWS Config rule. The results indicate which AWS resources were evaluated by the rule, when each resource was last evaluated, and whether each resource complies with the rule.
  ## 
  let valid = call_600653.validator(path, query, header, formData, body)
  let scheme = call_600653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600653.url(scheme.get, call_600653.host, call_600653.base,
                         call_600653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600653, url, valid)

proc call*(call_600654: Call_GetComplianceDetailsByConfigRule_600641;
          body: JsonNode): Recallable =
  ## getComplianceDetailsByConfigRule
  ## Returns the evaluation results for the specified AWS Config rule. The results indicate which AWS resources were evaluated by the rule, when each resource was last evaluated, and whether each resource complies with the rule.
  ##   body: JObject (required)
  var body_600655 = newJObject()
  if body != nil:
    body_600655 = body
  result = call_600654.call(nil, nil, nil, nil, body_600655)

var getComplianceDetailsByConfigRule* = Call_GetComplianceDetailsByConfigRule_600641(
    name: "getComplianceDetailsByConfigRule", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetComplianceDetailsByConfigRule",
    validator: validate_GetComplianceDetailsByConfigRule_600642, base: "/",
    url: url_GetComplianceDetailsByConfigRule_600643,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComplianceDetailsByResource_600656 = ref object of OpenApiRestCall_599368
proc url_GetComplianceDetailsByResource_600658(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComplianceDetailsByResource_600657(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600659 = header.getOrDefault("X-Amz-Date")
  valid_600659 = validateParameter(valid_600659, JString, required = false,
                                 default = nil)
  if valid_600659 != nil:
    section.add "X-Amz-Date", valid_600659
  var valid_600660 = header.getOrDefault("X-Amz-Security-Token")
  valid_600660 = validateParameter(valid_600660, JString, required = false,
                                 default = nil)
  if valid_600660 != nil:
    section.add "X-Amz-Security-Token", valid_600660
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600661 = header.getOrDefault("X-Amz-Target")
  valid_600661 = validateParameter(valid_600661, JString, required = true, default = newJString(
      "StarlingDoveService.GetComplianceDetailsByResource"))
  if valid_600661 != nil:
    section.add "X-Amz-Target", valid_600661
  var valid_600662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600662 = validateParameter(valid_600662, JString, required = false,
                                 default = nil)
  if valid_600662 != nil:
    section.add "X-Amz-Content-Sha256", valid_600662
  var valid_600663 = header.getOrDefault("X-Amz-Algorithm")
  valid_600663 = validateParameter(valid_600663, JString, required = false,
                                 default = nil)
  if valid_600663 != nil:
    section.add "X-Amz-Algorithm", valid_600663
  var valid_600664 = header.getOrDefault("X-Amz-Signature")
  valid_600664 = validateParameter(valid_600664, JString, required = false,
                                 default = nil)
  if valid_600664 != nil:
    section.add "X-Amz-Signature", valid_600664
  var valid_600665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600665 = validateParameter(valid_600665, JString, required = false,
                                 default = nil)
  if valid_600665 != nil:
    section.add "X-Amz-SignedHeaders", valid_600665
  var valid_600666 = header.getOrDefault("X-Amz-Credential")
  valid_600666 = validateParameter(valid_600666, JString, required = false,
                                 default = nil)
  if valid_600666 != nil:
    section.add "X-Amz-Credential", valid_600666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600668: Call_GetComplianceDetailsByResource_600656; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the evaluation results for the specified AWS resource. The results indicate which AWS Config rules were used to evaluate the resource, when each rule was last used, and whether the resource complies with each rule.
  ## 
  let valid = call_600668.validator(path, query, header, formData, body)
  let scheme = call_600668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600668.url(scheme.get, call_600668.host, call_600668.base,
                         call_600668.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600668, url, valid)

proc call*(call_600669: Call_GetComplianceDetailsByResource_600656; body: JsonNode): Recallable =
  ## getComplianceDetailsByResource
  ## Returns the evaluation results for the specified AWS resource. The results indicate which AWS Config rules were used to evaluate the resource, when each rule was last used, and whether the resource complies with each rule.
  ##   body: JObject (required)
  var body_600670 = newJObject()
  if body != nil:
    body_600670 = body
  result = call_600669.call(nil, nil, nil, nil, body_600670)

var getComplianceDetailsByResource* = Call_GetComplianceDetailsByResource_600656(
    name: "getComplianceDetailsByResource", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.GetComplianceDetailsByResource",
    validator: validate_GetComplianceDetailsByResource_600657, base: "/",
    url: url_GetComplianceDetailsByResource_600658,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComplianceSummaryByConfigRule_600671 = ref object of OpenApiRestCall_599368
proc url_GetComplianceSummaryByConfigRule_600673(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComplianceSummaryByConfigRule_600672(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600674 = header.getOrDefault("X-Amz-Date")
  valid_600674 = validateParameter(valid_600674, JString, required = false,
                                 default = nil)
  if valid_600674 != nil:
    section.add "X-Amz-Date", valid_600674
  var valid_600675 = header.getOrDefault("X-Amz-Security-Token")
  valid_600675 = validateParameter(valid_600675, JString, required = false,
                                 default = nil)
  if valid_600675 != nil:
    section.add "X-Amz-Security-Token", valid_600675
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600676 = header.getOrDefault("X-Amz-Target")
  valid_600676 = validateParameter(valid_600676, JString, required = true, default = newJString(
      "StarlingDoveService.GetComplianceSummaryByConfigRule"))
  if valid_600676 != nil:
    section.add "X-Amz-Target", valid_600676
  var valid_600677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600677 = validateParameter(valid_600677, JString, required = false,
                                 default = nil)
  if valid_600677 != nil:
    section.add "X-Amz-Content-Sha256", valid_600677
  var valid_600678 = header.getOrDefault("X-Amz-Algorithm")
  valid_600678 = validateParameter(valid_600678, JString, required = false,
                                 default = nil)
  if valid_600678 != nil:
    section.add "X-Amz-Algorithm", valid_600678
  var valid_600679 = header.getOrDefault("X-Amz-Signature")
  valid_600679 = validateParameter(valid_600679, JString, required = false,
                                 default = nil)
  if valid_600679 != nil:
    section.add "X-Amz-Signature", valid_600679
  var valid_600680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600680 = validateParameter(valid_600680, JString, required = false,
                                 default = nil)
  if valid_600680 != nil:
    section.add "X-Amz-SignedHeaders", valid_600680
  var valid_600681 = header.getOrDefault("X-Amz-Credential")
  valid_600681 = validateParameter(valid_600681, JString, required = false,
                                 default = nil)
  if valid_600681 != nil:
    section.add "X-Amz-Credential", valid_600681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600682: Call_GetComplianceSummaryByConfigRule_600671;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the number of AWS Config rules that are compliant and noncompliant, up to a maximum of 25 for each.
  ## 
  let valid = call_600682.validator(path, query, header, formData, body)
  let scheme = call_600682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600682.url(scheme.get, call_600682.host, call_600682.base,
                         call_600682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600682, url, valid)

proc call*(call_600683: Call_GetComplianceSummaryByConfigRule_600671): Recallable =
  ## getComplianceSummaryByConfigRule
  ## Returns the number of AWS Config rules that are compliant and noncompliant, up to a maximum of 25 for each.
  result = call_600683.call(nil, nil, nil, nil, nil)

var getComplianceSummaryByConfigRule* = Call_GetComplianceSummaryByConfigRule_600671(
    name: "getComplianceSummaryByConfigRule", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetComplianceSummaryByConfigRule",
    validator: validate_GetComplianceSummaryByConfigRule_600672, base: "/",
    url: url_GetComplianceSummaryByConfigRule_600673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComplianceSummaryByResourceType_600684 = ref object of OpenApiRestCall_599368
proc url_GetComplianceSummaryByResourceType_600686(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComplianceSummaryByResourceType_600685(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600687 = header.getOrDefault("X-Amz-Date")
  valid_600687 = validateParameter(valid_600687, JString, required = false,
                                 default = nil)
  if valid_600687 != nil:
    section.add "X-Amz-Date", valid_600687
  var valid_600688 = header.getOrDefault("X-Amz-Security-Token")
  valid_600688 = validateParameter(valid_600688, JString, required = false,
                                 default = nil)
  if valid_600688 != nil:
    section.add "X-Amz-Security-Token", valid_600688
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600689 = header.getOrDefault("X-Amz-Target")
  valid_600689 = validateParameter(valid_600689, JString, required = true, default = newJString(
      "StarlingDoveService.GetComplianceSummaryByResourceType"))
  if valid_600689 != nil:
    section.add "X-Amz-Target", valid_600689
  var valid_600690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600690 = validateParameter(valid_600690, JString, required = false,
                                 default = nil)
  if valid_600690 != nil:
    section.add "X-Amz-Content-Sha256", valid_600690
  var valid_600691 = header.getOrDefault("X-Amz-Algorithm")
  valid_600691 = validateParameter(valid_600691, JString, required = false,
                                 default = nil)
  if valid_600691 != nil:
    section.add "X-Amz-Algorithm", valid_600691
  var valid_600692 = header.getOrDefault("X-Amz-Signature")
  valid_600692 = validateParameter(valid_600692, JString, required = false,
                                 default = nil)
  if valid_600692 != nil:
    section.add "X-Amz-Signature", valid_600692
  var valid_600693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600693 = validateParameter(valid_600693, JString, required = false,
                                 default = nil)
  if valid_600693 != nil:
    section.add "X-Amz-SignedHeaders", valid_600693
  var valid_600694 = header.getOrDefault("X-Amz-Credential")
  valid_600694 = validateParameter(valid_600694, JString, required = false,
                                 default = nil)
  if valid_600694 != nil:
    section.add "X-Amz-Credential", valid_600694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600696: Call_GetComplianceSummaryByResourceType_600684;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the number of resources that are compliant and the number that are noncompliant. You can specify one or more resource types to get these numbers for each resource type. The maximum number returned is 100.
  ## 
  let valid = call_600696.validator(path, query, header, formData, body)
  let scheme = call_600696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600696.url(scheme.get, call_600696.host, call_600696.base,
                         call_600696.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600696, url, valid)

proc call*(call_600697: Call_GetComplianceSummaryByResourceType_600684;
          body: JsonNode): Recallable =
  ## getComplianceSummaryByResourceType
  ## Returns the number of resources that are compliant and the number that are noncompliant. You can specify one or more resource types to get these numbers for each resource type. The maximum number returned is 100.
  ##   body: JObject (required)
  var body_600698 = newJObject()
  if body != nil:
    body_600698 = body
  result = call_600697.call(nil, nil, nil, nil, body_600698)

var getComplianceSummaryByResourceType* = Call_GetComplianceSummaryByResourceType_600684(
    name: "getComplianceSummaryByResourceType", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetComplianceSummaryByResourceType",
    validator: validate_GetComplianceSummaryByResourceType_600685, base: "/",
    url: url_GetComplianceSummaryByResourceType_600686,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConformancePackComplianceDetails_600699 = ref object of OpenApiRestCall_599368
proc url_GetConformancePackComplianceDetails_600701(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConformancePackComplianceDetails_600700(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600702 = header.getOrDefault("X-Amz-Date")
  valid_600702 = validateParameter(valid_600702, JString, required = false,
                                 default = nil)
  if valid_600702 != nil:
    section.add "X-Amz-Date", valid_600702
  var valid_600703 = header.getOrDefault("X-Amz-Security-Token")
  valid_600703 = validateParameter(valid_600703, JString, required = false,
                                 default = nil)
  if valid_600703 != nil:
    section.add "X-Amz-Security-Token", valid_600703
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600704 = header.getOrDefault("X-Amz-Target")
  valid_600704 = validateParameter(valid_600704, JString, required = true, default = newJString(
      "StarlingDoveService.GetConformancePackComplianceDetails"))
  if valid_600704 != nil:
    section.add "X-Amz-Target", valid_600704
  var valid_600705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600705 = validateParameter(valid_600705, JString, required = false,
                                 default = nil)
  if valid_600705 != nil:
    section.add "X-Amz-Content-Sha256", valid_600705
  var valid_600706 = header.getOrDefault("X-Amz-Algorithm")
  valid_600706 = validateParameter(valid_600706, JString, required = false,
                                 default = nil)
  if valid_600706 != nil:
    section.add "X-Amz-Algorithm", valid_600706
  var valid_600707 = header.getOrDefault("X-Amz-Signature")
  valid_600707 = validateParameter(valid_600707, JString, required = false,
                                 default = nil)
  if valid_600707 != nil:
    section.add "X-Amz-Signature", valid_600707
  var valid_600708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600708 = validateParameter(valid_600708, JString, required = false,
                                 default = nil)
  if valid_600708 != nil:
    section.add "X-Amz-SignedHeaders", valid_600708
  var valid_600709 = header.getOrDefault("X-Amz-Credential")
  valid_600709 = validateParameter(valid_600709, JString, required = false,
                                 default = nil)
  if valid_600709 != nil:
    section.add "X-Amz-Credential", valid_600709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600711: Call_GetConformancePackComplianceDetails_600699;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns compliance details of a conformance pack for all AWS resources that are monitered by conformance pack.
  ## 
  let valid = call_600711.validator(path, query, header, formData, body)
  let scheme = call_600711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600711.url(scheme.get, call_600711.host, call_600711.base,
                         call_600711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600711, url, valid)

proc call*(call_600712: Call_GetConformancePackComplianceDetails_600699;
          body: JsonNode): Recallable =
  ## getConformancePackComplianceDetails
  ## Returns compliance details of a conformance pack for all AWS resources that are monitered by conformance pack.
  ##   body: JObject (required)
  var body_600713 = newJObject()
  if body != nil:
    body_600713 = body
  result = call_600712.call(nil, nil, nil, nil, body_600713)

var getConformancePackComplianceDetails* = Call_GetConformancePackComplianceDetails_600699(
    name: "getConformancePackComplianceDetails", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetConformancePackComplianceDetails",
    validator: validate_GetConformancePackComplianceDetails_600700, base: "/",
    url: url_GetConformancePackComplianceDetails_600701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConformancePackComplianceSummary_600714 = ref object of OpenApiRestCall_599368
proc url_GetConformancePackComplianceSummary_600716(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConformancePackComplianceSummary_600715(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600717 = header.getOrDefault("X-Amz-Date")
  valid_600717 = validateParameter(valid_600717, JString, required = false,
                                 default = nil)
  if valid_600717 != nil:
    section.add "X-Amz-Date", valid_600717
  var valid_600718 = header.getOrDefault("X-Amz-Security-Token")
  valid_600718 = validateParameter(valid_600718, JString, required = false,
                                 default = nil)
  if valid_600718 != nil:
    section.add "X-Amz-Security-Token", valid_600718
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600719 = header.getOrDefault("X-Amz-Target")
  valid_600719 = validateParameter(valid_600719, JString, required = true, default = newJString(
      "StarlingDoveService.GetConformancePackComplianceSummary"))
  if valid_600719 != nil:
    section.add "X-Amz-Target", valid_600719
  var valid_600720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600720 = validateParameter(valid_600720, JString, required = false,
                                 default = nil)
  if valid_600720 != nil:
    section.add "X-Amz-Content-Sha256", valid_600720
  var valid_600721 = header.getOrDefault("X-Amz-Algorithm")
  valid_600721 = validateParameter(valid_600721, JString, required = false,
                                 default = nil)
  if valid_600721 != nil:
    section.add "X-Amz-Algorithm", valid_600721
  var valid_600722 = header.getOrDefault("X-Amz-Signature")
  valid_600722 = validateParameter(valid_600722, JString, required = false,
                                 default = nil)
  if valid_600722 != nil:
    section.add "X-Amz-Signature", valid_600722
  var valid_600723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600723 = validateParameter(valid_600723, JString, required = false,
                                 default = nil)
  if valid_600723 != nil:
    section.add "X-Amz-SignedHeaders", valid_600723
  var valid_600724 = header.getOrDefault("X-Amz-Credential")
  valid_600724 = validateParameter(valid_600724, JString, required = false,
                                 default = nil)
  if valid_600724 != nil:
    section.add "X-Amz-Credential", valid_600724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600726: Call_GetConformancePackComplianceSummary_600714;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns compliance details for the conformance pack based on the cumulative compliance results of all the rules in that conformance pack.
  ## 
  let valid = call_600726.validator(path, query, header, formData, body)
  let scheme = call_600726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600726.url(scheme.get, call_600726.host, call_600726.base,
                         call_600726.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600726, url, valid)

proc call*(call_600727: Call_GetConformancePackComplianceSummary_600714;
          body: JsonNode): Recallable =
  ## getConformancePackComplianceSummary
  ## Returns compliance details for the conformance pack based on the cumulative compliance results of all the rules in that conformance pack.
  ##   body: JObject (required)
  var body_600728 = newJObject()
  if body != nil:
    body_600728 = body
  result = call_600727.call(nil, nil, nil, nil, body_600728)

var getConformancePackComplianceSummary* = Call_GetConformancePackComplianceSummary_600714(
    name: "getConformancePackComplianceSummary", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetConformancePackComplianceSummary",
    validator: validate_GetConformancePackComplianceSummary_600715, base: "/",
    url: url_GetConformancePackComplianceSummary_600716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiscoveredResourceCounts_600729 = ref object of OpenApiRestCall_599368
proc url_GetDiscoveredResourceCounts_600731(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDiscoveredResourceCounts_600730(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600732 = header.getOrDefault("X-Amz-Date")
  valid_600732 = validateParameter(valid_600732, JString, required = false,
                                 default = nil)
  if valid_600732 != nil:
    section.add "X-Amz-Date", valid_600732
  var valid_600733 = header.getOrDefault("X-Amz-Security-Token")
  valid_600733 = validateParameter(valid_600733, JString, required = false,
                                 default = nil)
  if valid_600733 != nil:
    section.add "X-Amz-Security-Token", valid_600733
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600734 = header.getOrDefault("X-Amz-Target")
  valid_600734 = validateParameter(valid_600734, JString, required = true, default = newJString(
      "StarlingDoveService.GetDiscoveredResourceCounts"))
  if valid_600734 != nil:
    section.add "X-Amz-Target", valid_600734
  var valid_600735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600735 = validateParameter(valid_600735, JString, required = false,
                                 default = nil)
  if valid_600735 != nil:
    section.add "X-Amz-Content-Sha256", valid_600735
  var valid_600736 = header.getOrDefault("X-Amz-Algorithm")
  valid_600736 = validateParameter(valid_600736, JString, required = false,
                                 default = nil)
  if valid_600736 != nil:
    section.add "X-Amz-Algorithm", valid_600736
  var valid_600737 = header.getOrDefault("X-Amz-Signature")
  valid_600737 = validateParameter(valid_600737, JString, required = false,
                                 default = nil)
  if valid_600737 != nil:
    section.add "X-Amz-Signature", valid_600737
  var valid_600738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600738 = validateParameter(valid_600738, JString, required = false,
                                 default = nil)
  if valid_600738 != nil:
    section.add "X-Amz-SignedHeaders", valid_600738
  var valid_600739 = header.getOrDefault("X-Amz-Credential")
  valid_600739 = validateParameter(valid_600739, JString, required = false,
                                 default = nil)
  if valid_600739 != nil:
    section.add "X-Amz-Credential", valid_600739
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600741: Call_GetDiscoveredResourceCounts_600729; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the resource types, the number of each resource type, and the total number of resources that AWS Config is recording in this region for your AWS account. </p> <p class="title"> <b>Example</b> </p> <ol> <li> <p>AWS Config is recording three resource types in the US East (Ohio) Region for your account: 25 EC2 instances, 20 IAM users, and 15 S3 buckets.</p> </li> <li> <p>You make a call to the <code>GetDiscoveredResourceCounts</code> action and specify that you want all resource types. </p> </li> <li> <p>AWS Config returns the following:</p> <ul> <li> <p>The resource types (EC2 instances, IAM users, and S3 buckets).</p> </li> <li> <p>The number of each resource type (25, 20, and 15).</p> </li> <li> <p>The total number of all resources (60).</p> </li> </ul> </li> </ol> <p>The response is paginated. By default, AWS Config lists 100 <a>ResourceCount</a> objects on each page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p> <note> <p>If you make a call to the <a>GetDiscoveredResourceCounts</a> action, you might not immediately receive resource counts in the following situations:</p> <ul> <li> <p>You are a new AWS Config customer.</p> </li> <li> <p>You just enabled resource recording.</p> </li> </ul> <p>It might take a few minutes for AWS Config to record and count your resources. Wait a few minutes and then retry the <a>GetDiscoveredResourceCounts</a> action. </p> </note>
  ## 
  let valid = call_600741.validator(path, query, header, formData, body)
  let scheme = call_600741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600741.url(scheme.get, call_600741.host, call_600741.base,
                         call_600741.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600741, url, valid)

proc call*(call_600742: Call_GetDiscoveredResourceCounts_600729; body: JsonNode): Recallable =
  ## getDiscoveredResourceCounts
  ## <p>Returns the resource types, the number of each resource type, and the total number of resources that AWS Config is recording in this region for your AWS account. </p> <p class="title"> <b>Example</b> </p> <ol> <li> <p>AWS Config is recording three resource types in the US East (Ohio) Region for your account: 25 EC2 instances, 20 IAM users, and 15 S3 buckets.</p> </li> <li> <p>You make a call to the <code>GetDiscoveredResourceCounts</code> action and specify that you want all resource types. </p> </li> <li> <p>AWS Config returns the following:</p> <ul> <li> <p>The resource types (EC2 instances, IAM users, and S3 buckets).</p> </li> <li> <p>The number of each resource type (25, 20, and 15).</p> </li> <li> <p>The total number of all resources (60).</p> </li> </ul> </li> </ol> <p>The response is paginated. By default, AWS Config lists 100 <a>ResourceCount</a> objects on each page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p> <note> <p>If you make a call to the <a>GetDiscoveredResourceCounts</a> action, you might not immediately receive resource counts in the following situations:</p> <ul> <li> <p>You are a new AWS Config customer.</p> </li> <li> <p>You just enabled resource recording.</p> </li> </ul> <p>It might take a few minutes for AWS Config to record and count your resources. Wait a few minutes and then retry the <a>GetDiscoveredResourceCounts</a> action. </p> </note>
  ##   body: JObject (required)
  var body_600743 = newJObject()
  if body != nil:
    body_600743 = body
  result = call_600742.call(nil, nil, nil, nil, body_600743)

var getDiscoveredResourceCounts* = Call_GetDiscoveredResourceCounts_600729(
    name: "getDiscoveredResourceCounts", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.GetDiscoveredResourceCounts",
    validator: validate_GetDiscoveredResourceCounts_600730, base: "/",
    url: url_GetDiscoveredResourceCounts_600731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOrganizationConfigRuleDetailedStatus_600744 = ref object of OpenApiRestCall_599368
proc url_GetOrganizationConfigRuleDetailedStatus_600746(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOrganizationConfigRuleDetailedStatus_600745(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600747 = header.getOrDefault("X-Amz-Date")
  valid_600747 = validateParameter(valid_600747, JString, required = false,
                                 default = nil)
  if valid_600747 != nil:
    section.add "X-Amz-Date", valid_600747
  var valid_600748 = header.getOrDefault("X-Amz-Security-Token")
  valid_600748 = validateParameter(valid_600748, JString, required = false,
                                 default = nil)
  if valid_600748 != nil:
    section.add "X-Amz-Security-Token", valid_600748
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600749 = header.getOrDefault("X-Amz-Target")
  valid_600749 = validateParameter(valid_600749, JString, required = true, default = newJString(
      "StarlingDoveService.GetOrganizationConfigRuleDetailedStatus"))
  if valid_600749 != nil:
    section.add "X-Amz-Target", valid_600749
  var valid_600750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600750 = validateParameter(valid_600750, JString, required = false,
                                 default = nil)
  if valid_600750 != nil:
    section.add "X-Amz-Content-Sha256", valid_600750
  var valid_600751 = header.getOrDefault("X-Amz-Algorithm")
  valid_600751 = validateParameter(valid_600751, JString, required = false,
                                 default = nil)
  if valid_600751 != nil:
    section.add "X-Amz-Algorithm", valid_600751
  var valid_600752 = header.getOrDefault("X-Amz-Signature")
  valid_600752 = validateParameter(valid_600752, JString, required = false,
                                 default = nil)
  if valid_600752 != nil:
    section.add "X-Amz-Signature", valid_600752
  var valid_600753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600753 = validateParameter(valid_600753, JString, required = false,
                                 default = nil)
  if valid_600753 != nil:
    section.add "X-Amz-SignedHeaders", valid_600753
  var valid_600754 = header.getOrDefault("X-Amz-Credential")
  valid_600754 = validateParameter(valid_600754, JString, required = false,
                                 default = nil)
  if valid_600754 != nil:
    section.add "X-Amz-Credential", valid_600754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600756: Call_GetOrganizationConfigRuleDetailedStatus_600744;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns detailed status for each member account within an organization for a given organization config rule.</p> <note> <p>Only a master account can call this API.</p> </note>
  ## 
  let valid = call_600756.validator(path, query, header, formData, body)
  let scheme = call_600756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600756.url(scheme.get, call_600756.host, call_600756.base,
                         call_600756.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600756, url, valid)

proc call*(call_600757: Call_GetOrganizationConfigRuleDetailedStatus_600744;
          body: JsonNode): Recallable =
  ## getOrganizationConfigRuleDetailedStatus
  ## <p>Returns detailed status for each member account within an organization for a given organization config rule.</p> <note> <p>Only a master account can call this API.</p> </note>
  ##   body: JObject (required)
  var body_600758 = newJObject()
  if body != nil:
    body_600758 = body
  result = call_600757.call(nil, nil, nil, nil, body_600758)

var getOrganizationConfigRuleDetailedStatus* = Call_GetOrganizationConfigRuleDetailedStatus_600744(
    name: "getOrganizationConfigRuleDetailedStatus", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetOrganizationConfigRuleDetailedStatus",
    validator: validate_GetOrganizationConfigRuleDetailedStatus_600745, base: "/",
    url: url_GetOrganizationConfigRuleDetailedStatus_600746,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOrganizationConformancePackDetailedStatus_600759 = ref object of OpenApiRestCall_599368
proc url_GetOrganizationConformancePackDetailedStatus_600761(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOrganizationConformancePackDetailedStatus_600760(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600762 = header.getOrDefault("X-Amz-Date")
  valid_600762 = validateParameter(valid_600762, JString, required = false,
                                 default = nil)
  if valid_600762 != nil:
    section.add "X-Amz-Date", valid_600762
  var valid_600763 = header.getOrDefault("X-Amz-Security-Token")
  valid_600763 = validateParameter(valid_600763, JString, required = false,
                                 default = nil)
  if valid_600763 != nil:
    section.add "X-Amz-Security-Token", valid_600763
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600764 = header.getOrDefault("X-Amz-Target")
  valid_600764 = validateParameter(valid_600764, JString, required = true, default = newJString(
      "StarlingDoveService.GetOrganizationConformancePackDetailedStatus"))
  if valid_600764 != nil:
    section.add "X-Amz-Target", valid_600764
  var valid_600765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600765 = validateParameter(valid_600765, JString, required = false,
                                 default = nil)
  if valid_600765 != nil:
    section.add "X-Amz-Content-Sha256", valid_600765
  var valid_600766 = header.getOrDefault("X-Amz-Algorithm")
  valid_600766 = validateParameter(valid_600766, JString, required = false,
                                 default = nil)
  if valid_600766 != nil:
    section.add "X-Amz-Algorithm", valid_600766
  var valid_600767 = header.getOrDefault("X-Amz-Signature")
  valid_600767 = validateParameter(valid_600767, JString, required = false,
                                 default = nil)
  if valid_600767 != nil:
    section.add "X-Amz-Signature", valid_600767
  var valid_600768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600768 = validateParameter(valid_600768, JString, required = false,
                                 default = nil)
  if valid_600768 != nil:
    section.add "X-Amz-SignedHeaders", valid_600768
  var valid_600769 = header.getOrDefault("X-Amz-Credential")
  valid_600769 = validateParameter(valid_600769, JString, required = false,
                                 default = nil)
  if valid_600769 != nil:
    section.add "X-Amz-Credential", valid_600769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600771: Call_GetOrganizationConformancePackDetailedStatus_600759;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns detailed status for each member account within an organization for a given organization conformance pack.</p> <p>Only a master account can call this API.</p>
  ## 
  let valid = call_600771.validator(path, query, header, formData, body)
  let scheme = call_600771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600771.url(scheme.get, call_600771.host, call_600771.base,
                         call_600771.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600771, url, valid)

proc call*(call_600772: Call_GetOrganizationConformancePackDetailedStatus_600759;
          body: JsonNode): Recallable =
  ## getOrganizationConformancePackDetailedStatus
  ## <p>Returns detailed status for each member account within an organization for a given organization conformance pack.</p> <p>Only a master account can call this API.</p>
  ##   body: JObject (required)
  var body_600773 = newJObject()
  if body != nil:
    body_600773 = body
  result = call_600772.call(nil, nil, nil, nil, body_600773)

var getOrganizationConformancePackDetailedStatus* = Call_GetOrganizationConformancePackDetailedStatus_600759(
    name: "getOrganizationConformancePackDetailedStatus",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetOrganizationConformancePackDetailedStatus",
    validator: validate_GetOrganizationConformancePackDetailedStatus_600760,
    base: "/", url: url_GetOrganizationConformancePackDetailedStatus_600761,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceConfigHistory_600774 = ref object of OpenApiRestCall_599368
proc url_GetResourceConfigHistory_600776(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResourceConfigHistory_600775(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600777 = query.getOrDefault("nextToken")
  valid_600777 = validateParameter(valid_600777, JString, required = false,
                                 default = nil)
  if valid_600777 != nil:
    section.add "nextToken", valid_600777
  var valid_600778 = query.getOrDefault("limit")
  valid_600778 = validateParameter(valid_600778, JString, required = false,
                                 default = nil)
  if valid_600778 != nil:
    section.add "limit", valid_600778
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
  var valid_600779 = header.getOrDefault("X-Amz-Date")
  valid_600779 = validateParameter(valid_600779, JString, required = false,
                                 default = nil)
  if valid_600779 != nil:
    section.add "X-Amz-Date", valid_600779
  var valid_600780 = header.getOrDefault("X-Amz-Security-Token")
  valid_600780 = validateParameter(valid_600780, JString, required = false,
                                 default = nil)
  if valid_600780 != nil:
    section.add "X-Amz-Security-Token", valid_600780
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600781 = header.getOrDefault("X-Amz-Target")
  valid_600781 = validateParameter(valid_600781, JString, required = true, default = newJString(
      "StarlingDoveService.GetResourceConfigHistory"))
  if valid_600781 != nil:
    section.add "X-Amz-Target", valid_600781
  var valid_600782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600782 = validateParameter(valid_600782, JString, required = false,
                                 default = nil)
  if valid_600782 != nil:
    section.add "X-Amz-Content-Sha256", valid_600782
  var valid_600783 = header.getOrDefault("X-Amz-Algorithm")
  valid_600783 = validateParameter(valid_600783, JString, required = false,
                                 default = nil)
  if valid_600783 != nil:
    section.add "X-Amz-Algorithm", valid_600783
  var valid_600784 = header.getOrDefault("X-Amz-Signature")
  valid_600784 = validateParameter(valid_600784, JString, required = false,
                                 default = nil)
  if valid_600784 != nil:
    section.add "X-Amz-Signature", valid_600784
  var valid_600785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600785 = validateParameter(valid_600785, JString, required = false,
                                 default = nil)
  if valid_600785 != nil:
    section.add "X-Amz-SignedHeaders", valid_600785
  var valid_600786 = header.getOrDefault("X-Amz-Credential")
  valid_600786 = validateParameter(valid_600786, JString, required = false,
                                 default = nil)
  if valid_600786 != nil:
    section.add "X-Amz-Credential", valid_600786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600788: Call_GetResourceConfigHistory_600774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of configuration items for the specified resource. The list contains details about each state of the resource during the specified time interval. If you specified a retention period to retain your <code>ConfigurationItems</code> between a minimum of 30 days and a maximum of 7 years (2557 days), AWS Config returns the <code>ConfigurationItems</code> for the specified retention period. </p> <p>The response is paginated. By default, AWS Config returns a limit of 10 configuration items per page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p> <note> <p>Each call to the API is limited to span a duration of seven days. It is likely that the number of records returned is smaller than the specified <code>limit</code>. In such cases, you can make another call, using the <code>nextToken</code>.</p> </note>
  ## 
  let valid = call_600788.validator(path, query, header, formData, body)
  let scheme = call_600788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600788.url(scheme.get, call_600788.host, call_600788.base,
                         call_600788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600788, url, valid)

proc call*(call_600789: Call_GetResourceConfigHistory_600774; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## getResourceConfigHistory
  ## <p>Returns a list of configuration items for the specified resource. The list contains details about each state of the resource during the specified time interval. If you specified a retention period to retain your <code>ConfigurationItems</code> between a minimum of 30 days and a maximum of 7 years (2557 days), AWS Config returns the <code>ConfigurationItems</code> for the specified retention period. </p> <p>The response is paginated. By default, AWS Config returns a limit of 10 configuration items per page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p> <note> <p>Each call to the API is limited to span a duration of seven days. It is likely that the number of records returned is smaller than the specified <code>limit</code>. In such cases, you can make another call, using the <code>nextToken</code>.</p> </note>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   limit: string
  ##        : Pagination limit
  var query_600790 = newJObject()
  var body_600791 = newJObject()
  add(query_600790, "nextToken", newJString(nextToken))
  if body != nil:
    body_600791 = body
  add(query_600790, "limit", newJString(limit))
  result = call_600789.call(nil, query_600790, nil, nil, body_600791)

var getResourceConfigHistory* = Call_GetResourceConfigHistory_600774(
    name: "getResourceConfigHistory", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.GetResourceConfigHistory",
    validator: validate_GetResourceConfigHistory_600775, base: "/",
    url: url_GetResourceConfigHistory_600776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAggregateDiscoveredResources_600792 = ref object of OpenApiRestCall_599368
proc url_ListAggregateDiscoveredResources_600794(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAggregateDiscoveredResources_600793(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600795 = header.getOrDefault("X-Amz-Date")
  valid_600795 = validateParameter(valid_600795, JString, required = false,
                                 default = nil)
  if valid_600795 != nil:
    section.add "X-Amz-Date", valid_600795
  var valid_600796 = header.getOrDefault("X-Amz-Security-Token")
  valid_600796 = validateParameter(valid_600796, JString, required = false,
                                 default = nil)
  if valid_600796 != nil:
    section.add "X-Amz-Security-Token", valid_600796
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600797 = header.getOrDefault("X-Amz-Target")
  valid_600797 = validateParameter(valid_600797, JString, required = true, default = newJString(
      "StarlingDoveService.ListAggregateDiscoveredResources"))
  if valid_600797 != nil:
    section.add "X-Amz-Target", valid_600797
  var valid_600798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600798 = validateParameter(valid_600798, JString, required = false,
                                 default = nil)
  if valid_600798 != nil:
    section.add "X-Amz-Content-Sha256", valid_600798
  var valid_600799 = header.getOrDefault("X-Amz-Algorithm")
  valid_600799 = validateParameter(valid_600799, JString, required = false,
                                 default = nil)
  if valid_600799 != nil:
    section.add "X-Amz-Algorithm", valid_600799
  var valid_600800 = header.getOrDefault("X-Amz-Signature")
  valid_600800 = validateParameter(valid_600800, JString, required = false,
                                 default = nil)
  if valid_600800 != nil:
    section.add "X-Amz-Signature", valid_600800
  var valid_600801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600801 = validateParameter(valid_600801, JString, required = false,
                                 default = nil)
  if valid_600801 != nil:
    section.add "X-Amz-SignedHeaders", valid_600801
  var valid_600802 = header.getOrDefault("X-Amz-Credential")
  valid_600802 = validateParameter(valid_600802, JString, required = false,
                                 default = nil)
  if valid_600802 != nil:
    section.add "X-Amz-Credential", valid_600802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600804: Call_ListAggregateDiscoveredResources_600792;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a resource type and returns a list of resource identifiers that are aggregated for a specific resource type across accounts and regions. A resource identifier includes the resource type, ID, (if available) the custom resource name, source account, and source region. You can narrow the results to include only resources that have specific resource IDs, or a resource name, or source account ID, or source region.</p> <p>For example, if the input consists of accountID 12345678910 and the region is us-east-1 for resource type <code>AWS::EC2::Instance</code> then the API returns all the EC2 instance identifiers of accountID 12345678910 and region us-east-1.</p>
  ## 
  let valid = call_600804.validator(path, query, header, formData, body)
  let scheme = call_600804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600804.url(scheme.get, call_600804.host, call_600804.base,
                         call_600804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600804, url, valid)

proc call*(call_600805: Call_ListAggregateDiscoveredResources_600792;
          body: JsonNode): Recallable =
  ## listAggregateDiscoveredResources
  ## <p>Accepts a resource type and returns a list of resource identifiers that are aggregated for a specific resource type across accounts and regions. A resource identifier includes the resource type, ID, (if available) the custom resource name, source account, and source region. You can narrow the results to include only resources that have specific resource IDs, or a resource name, or source account ID, or source region.</p> <p>For example, if the input consists of accountID 12345678910 and the region is us-east-1 for resource type <code>AWS::EC2::Instance</code> then the API returns all the EC2 instance identifiers of accountID 12345678910 and region us-east-1.</p>
  ##   body: JObject (required)
  var body_600806 = newJObject()
  if body != nil:
    body_600806 = body
  result = call_600805.call(nil, nil, nil, nil, body_600806)

var listAggregateDiscoveredResources* = Call_ListAggregateDiscoveredResources_600792(
    name: "listAggregateDiscoveredResources", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.ListAggregateDiscoveredResources",
    validator: validate_ListAggregateDiscoveredResources_600793, base: "/",
    url: url_ListAggregateDiscoveredResources_600794,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDiscoveredResources_600807 = ref object of OpenApiRestCall_599368
proc url_ListDiscoveredResources_600809(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDiscoveredResources_600808(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600810 = header.getOrDefault("X-Amz-Date")
  valid_600810 = validateParameter(valid_600810, JString, required = false,
                                 default = nil)
  if valid_600810 != nil:
    section.add "X-Amz-Date", valid_600810
  var valid_600811 = header.getOrDefault("X-Amz-Security-Token")
  valid_600811 = validateParameter(valid_600811, JString, required = false,
                                 default = nil)
  if valid_600811 != nil:
    section.add "X-Amz-Security-Token", valid_600811
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600812 = header.getOrDefault("X-Amz-Target")
  valid_600812 = validateParameter(valid_600812, JString, required = true, default = newJString(
      "StarlingDoveService.ListDiscoveredResources"))
  if valid_600812 != nil:
    section.add "X-Amz-Target", valid_600812
  var valid_600813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600813 = validateParameter(valid_600813, JString, required = false,
                                 default = nil)
  if valid_600813 != nil:
    section.add "X-Amz-Content-Sha256", valid_600813
  var valid_600814 = header.getOrDefault("X-Amz-Algorithm")
  valid_600814 = validateParameter(valid_600814, JString, required = false,
                                 default = nil)
  if valid_600814 != nil:
    section.add "X-Amz-Algorithm", valid_600814
  var valid_600815 = header.getOrDefault("X-Amz-Signature")
  valid_600815 = validateParameter(valid_600815, JString, required = false,
                                 default = nil)
  if valid_600815 != nil:
    section.add "X-Amz-Signature", valid_600815
  var valid_600816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600816 = validateParameter(valid_600816, JString, required = false,
                                 default = nil)
  if valid_600816 != nil:
    section.add "X-Amz-SignedHeaders", valid_600816
  var valid_600817 = header.getOrDefault("X-Amz-Credential")
  valid_600817 = validateParameter(valid_600817, JString, required = false,
                                 default = nil)
  if valid_600817 != nil:
    section.add "X-Amz-Credential", valid_600817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600819: Call_ListDiscoveredResources_600807; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Accepts a resource type and returns a list of resource identifiers for the resources of that type. A resource identifier includes the resource type, ID, and (if available) the custom resource name. The results consist of resources that AWS Config has discovered, including those that AWS Config is not currently recording. You can narrow the results to include only resources that have specific resource IDs or a resource name.</p> <note> <p>You can specify either resource IDs or a resource name, but not both, in the same request.</p> </note> <p>The response is paginated. By default, AWS Config lists 100 resource identifiers on each page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p>
  ## 
  let valid = call_600819.validator(path, query, header, formData, body)
  let scheme = call_600819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600819.url(scheme.get, call_600819.host, call_600819.base,
                         call_600819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600819, url, valid)

proc call*(call_600820: Call_ListDiscoveredResources_600807; body: JsonNode): Recallable =
  ## listDiscoveredResources
  ## <p>Accepts a resource type and returns a list of resource identifiers for the resources of that type. A resource identifier includes the resource type, ID, and (if available) the custom resource name. The results consist of resources that AWS Config has discovered, including those that AWS Config is not currently recording. You can narrow the results to include only resources that have specific resource IDs or a resource name.</p> <note> <p>You can specify either resource IDs or a resource name, but not both, in the same request.</p> </note> <p>The response is paginated. By default, AWS Config lists 100 resource identifiers on each page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p>
  ##   body: JObject (required)
  var body_600821 = newJObject()
  if body != nil:
    body_600821 = body
  result = call_600820.call(nil, nil, nil, nil, body_600821)

var listDiscoveredResources* = Call_ListDiscoveredResources_600807(
    name: "listDiscoveredResources", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.ListDiscoveredResources",
    validator: validate_ListDiscoveredResources_600808, base: "/",
    url: url_ListDiscoveredResources_600809, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600822 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600824(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_600823(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_600825 = header.getOrDefault("X-Amz-Date")
  valid_600825 = validateParameter(valid_600825, JString, required = false,
                                 default = nil)
  if valid_600825 != nil:
    section.add "X-Amz-Date", valid_600825
  var valid_600826 = header.getOrDefault("X-Amz-Security-Token")
  valid_600826 = validateParameter(valid_600826, JString, required = false,
                                 default = nil)
  if valid_600826 != nil:
    section.add "X-Amz-Security-Token", valid_600826
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600827 = header.getOrDefault("X-Amz-Target")
  valid_600827 = validateParameter(valid_600827, JString, required = true, default = newJString(
      "StarlingDoveService.ListTagsForResource"))
  if valid_600827 != nil:
    section.add "X-Amz-Target", valid_600827
  var valid_600828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600828 = validateParameter(valid_600828, JString, required = false,
                                 default = nil)
  if valid_600828 != nil:
    section.add "X-Amz-Content-Sha256", valid_600828
  var valid_600829 = header.getOrDefault("X-Amz-Algorithm")
  valid_600829 = validateParameter(valid_600829, JString, required = false,
                                 default = nil)
  if valid_600829 != nil:
    section.add "X-Amz-Algorithm", valid_600829
  var valid_600830 = header.getOrDefault("X-Amz-Signature")
  valid_600830 = validateParameter(valid_600830, JString, required = false,
                                 default = nil)
  if valid_600830 != nil:
    section.add "X-Amz-Signature", valid_600830
  var valid_600831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600831 = validateParameter(valid_600831, JString, required = false,
                                 default = nil)
  if valid_600831 != nil:
    section.add "X-Amz-SignedHeaders", valid_600831
  var valid_600832 = header.getOrDefault("X-Amz-Credential")
  valid_600832 = validateParameter(valid_600832, JString, required = false,
                                 default = nil)
  if valid_600832 != nil:
    section.add "X-Amz-Credential", valid_600832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600834: Call_ListTagsForResource_600822; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for AWS Config resource.
  ## 
  let valid = call_600834.validator(path, query, header, formData, body)
  let scheme = call_600834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600834.url(scheme.get, call_600834.host, call_600834.base,
                         call_600834.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600834, url, valid)

proc call*(call_600835: Call_ListTagsForResource_600822; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for AWS Config resource.
  ##   body: JObject (required)
  var body_600836 = newJObject()
  if body != nil:
    body_600836 = body
  result = call_600835.call(nil, nil, nil, nil, body_600836)

var listTagsForResource* = Call_ListTagsForResource_600822(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.ListTagsForResource",
    validator: validate_ListTagsForResource_600823, base: "/",
    url: url_ListTagsForResource_600824, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAggregationAuthorization_600837 = ref object of OpenApiRestCall_599368
proc url_PutAggregationAuthorization_600839(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutAggregationAuthorization_600838(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600840 = header.getOrDefault("X-Amz-Date")
  valid_600840 = validateParameter(valid_600840, JString, required = false,
                                 default = nil)
  if valid_600840 != nil:
    section.add "X-Amz-Date", valid_600840
  var valid_600841 = header.getOrDefault("X-Amz-Security-Token")
  valid_600841 = validateParameter(valid_600841, JString, required = false,
                                 default = nil)
  if valid_600841 != nil:
    section.add "X-Amz-Security-Token", valid_600841
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600842 = header.getOrDefault("X-Amz-Target")
  valid_600842 = validateParameter(valid_600842, JString, required = true, default = newJString(
      "StarlingDoveService.PutAggregationAuthorization"))
  if valid_600842 != nil:
    section.add "X-Amz-Target", valid_600842
  var valid_600843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600843 = validateParameter(valid_600843, JString, required = false,
                                 default = nil)
  if valid_600843 != nil:
    section.add "X-Amz-Content-Sha256", valid_600843
  var valid_600844 = header.getOrDefault("X-Amz-Algorithm")
  valid_600844 = validateParameter(valid_600844, JString, required = false,
                                 default = nil)
  if valid_600844 != nil:
    section.add "X-Amz-Algorithm", valid_600844
  var valid_600845 = header.getOrDefault("X-Amz-Signature")
  valid_600845 = validateParameter(valid_600845, JString, required = false,
                                 default = nil)
  if valid_600845 != nil:
    section.add "X-Amz-Signature", valid_600845
  var valid_600846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600846 = validateParameter(valid_600846, JString, required = false,
                                 default = nil)
  if valid_600846 != nil:
    section.add "X-Amz-SignedHeaders", valid_600846
  var valid_600847 = header.getOrDefault("X-Amz-Credential")
  valid_600847 = validateParameter(valid_600847, JString, required = false,
                                 default = nil)
  if valid_600847 != nil:
    section.add "X-Amz-Credential", valid_600847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600849: Call_PutAggregationAuthorization_600837; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Authorizes the aggregator account and region to collect data from the source account and region. 
  ## 
  let valid = call_600849.validator(path, query, header, formData, body)
  let scheme = call_600849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600849.url(scheme.get, call_600849.host, call_600849.base,
                         call_600849.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600849, url, valid)

proc call*(call_600850: Call_PutAggregationAuthorization_600837; body: JsonNode): Recallable =
  ## putAggregationAuthorization
  ## Authorizes the aggregator account and region to collect data from the source account and region. 
  ##   body: JObject (required)
  var body_600851 = newJObject()
  if body != nil:
    body_600851 = body
  result = call_600850.call(nil, nil, nil, nil, body_600851)

var putAggregationAuthorization* = Call_PutAggregationAuthorization_600837(
    name: "putAggregationAuthorization", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutAggregationAuthorization",
    validator: validate_PutAggregationAuthorization_600838, base: "/",
    url: url_PutAggregationAuthorization_600839,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigRule_600852 = ref object of OpenApiRestCall_599368
proc url_PutConfigRule_600854(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutConfigRule_600853(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600855 = header.getOrDefault("X-Amz-Date")
  valid_600855 = validateParameter(valid_600855, JString, required = false,
                                 default = nil)
  if valid_600855 != nil:
    section.add "X-Amz-Date", valid_600855
  var valid_600856 = header.getOrDefault("X-Amz-Security-Token")
  valid_600856 = validateParameter(valid_600856, JString, required = false,
                                 default = nil)
  if valid_600856 != nil:
    section.add "X-Amz-Security-Token", valid_600856
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600857 = header.getOrDefault("X-Amz-Target")
  valid_600857 = validateParameter(valid_600857, JString, required = true, default = newJString(
      "StarlingDoveService.PutConfigRule"))
  if valid_600857 != nil:
    section.add "X-Amz-Target", valid_600857
  var valid_600858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600858 = validateParameter(valid_600858, JString, required = false,
                                 default = nil)
  if valid_600858 != nil:
    section.add "X-Amz-Content-Sha256", valid_600858
  var valid_600859 = header.getOrDefault("X-Amz-Algorithm")
  valid_600859 = validateParameter(valid_600859, JString, required = false,
                                 default = nil)
  if valid_600859 != nil:
    section.add "X-Amz-Algorithm", valid_600859
  var valid_600860 = header.getOrDefault("X-Amz-Signature")
  valid_600860 = validateParameter(valid_600860, JString, required = false,
                                 default = nil)
  if valid_600860 != nil:
    section.add "X-Amz-Signature", valid_600860
  var valid_600861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600861 = validateParameter(valid_600861, JString, required = false,
                                 default = nil)
  if valid_600861 != nil:
    section.add "X-Amz-SignedHeaders", valid_600861
  var valid_600862 = header.getOrDefault("X-Amz-Credential")
  valid_600862 = validateParameter(valid_600862, JString, required = false,
                                 default = nil)
  if valid_600862 != nil:
    section.add "X-Amz-Credential", valid_600862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600864: Call_PutConfigRule_600852; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or updates an AWS Config rule for evaluating whether your AWS resources comply with your desired configurations.</p> <p>You can use this action for custom AWS Config rules and AWS managed Config rules. A custom AWS Config rule is a rule that you develop and maintain. An AWS managed Config rule is a customizable, predefined rule that AWS Config provides.</p> <p>If you are adding a new custom AWS Config rule, you must first create the AWS Lambda function that the rule invokes to evaluate your resources. When you use the <code>PutConfigRule</code> action to add the rule to AWS Config, you must specify the Amazon Resource Name (ARN) that AWS Lambda assigns to the function. Specify the ARN for the <code>SourceIdentifier</code> key. This key is part of the <code>Source</code> object, which is part of the <code>ConfigRule</code> object. </p> <p>If you are adding an AWS managed Config rule, specify the rule's identifier for the <code>SourceIdentifier</code> key. To reference AWS managed Config rule identifiers, see <a href="https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config_use-managed-rules.html">About AWS Managed Config Rules</a>.</p> <p>For any new rule that you add, specify the <code>ConfigRuleName</code> in the <code>ConfigRule</code> object. Do not specify the <code>ConfigRuleArn</code> or the <code>ConfigRuleId</code>. These values are generated by AWS Config for new rules.</p> <p>If you are updating a rule that you added previously, you can specify the rule by <code>ConfigRuleName</code>, <code>ConfigRuleId</code>, or <code>ConfigRuleArn</code> in the <code>ConfigRule</code> data type that you use in this request.</p> <p>The maximum number of rules that AWS Config supports is 150.</p> <p>For information about requesting a rule limit increase, see <a href="http://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_config">AWS Config Limits</a> in the <i>AWS General Reference Guide</i>.</p> <p>For more information about developing and using AWS Config rules, see <a href="https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config.html">Evaluating AWS Resource Configurations with AWS Config</a> in the <i>AWS Config Developer Guide</i>.</p>
  ## 
  let valid = call_600864.validator(path, query, header, formData, body)
  let scheme = call_600864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600864.url(scheme.get, call_600864.host, call_600864.base,
                         call_600864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600864, url, valid)

proc call*(call_600865: Call_PutConfigRule_600852; body: JsonNode): Recallable =
  ## putConfigRule
  ## <p>Adds or updates an AWS Config rule for evaluating whether your AWS resources comply with your desired configurations.</p> <p>You can use this action for custom AWS Config rules and AWS managed Config rules. A custom AWS Config rule is a rule that you develop and maintain. An AWS managed Config rule is a customizable, predefined rule that AWS Config provides.</p> <p>If you are adding a new custom AWS Config rule, you must first create the AWS Lambda function that the rule invokes to evaluate your resources. When you use the <code>PutConfigRule</code> action to add the rule to AWS Config, you must specify the Amazon Resource Name (ARN) that AWS Lambda assigns to the function. Specify the ARN for the <code>SourceIdentifier</code> key. This key is part of the <code>Source</code> object, which is part of the <code>ConfigRule</code> object. </p> <p>If you are adding an AWS managed Config rule, specify the rule's identifier for the <code>SourceIdentifier</code> key. To reference AWS managed Config rule identifiers, see <a href="https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config_use-managed-rules.html">About AWS Managed Config Rules</a>.</p> <p>For any new rule that you add, specify the <code>ConfigRuleName</code> in the <code>ConfigRule</code> object. Do not specify the <code>ConfigRuleArn</code> or the <code>ConfigRuleId</code>. These values are generated by AWS Config for new rules.</p> <p>If you are updating a rule that you added previously, you can specify the rule by <code>ConfigRuleName</code>, <code>ConfigRuleId</code>, or <code>ConfigRuleArn</code> in the <code>ConfigRule</code> data type that you use in this request.</p> <p>The maximum number of rules that AWS Config supports is 150.</p> <p>For information about requesting a rule limit increase, see <a href="http://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_config">AWS Config Limits</a> in the <i>AWS General Reference Guide</i>.</p> <p>For more information about developing and using AWS Config rules, see <a href="https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config.html">Evaluating AWS Resource Configurations with AWS Config</a> in the <i>AWS Config Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_600866 = newJObject()
  if body != nil:
    body_600866 = body
  result = call_600865.call(nil, nil, nil, nil, body_600866)

var putConfigRule* = Call_PutConfigRule_600852(name: "putConfigRule",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutConfigRule",
    validator: validate_PutConfigRule_600853, base: "/", url: url_PutConfigRule_600854,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationAggregator_600867 = ref object of OpenApiRestCall_599368
proc url_PutConfigurationAggregator_600869(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutConfigurationAggregator_600868(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600870 = header.getOrDefault("X-Amz-Date")
  valid_600870 = validateParameter(valid_600870, JString, required = false,
                                 default = nil)
  if valid_600870 != nil:
    section.add "X-Amz-Date", valid_600870
  var valid_600871 = header.getOrDefault("X-Amz-Security-Token")
  valid_600871 = validateParameter(valid_600871, JString, required = false,
                                 default = nil)
  if valid_600871 != nil:
    section.add "X-Amz-Security-Token", valid_600871
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600872 = header.getOrDefault("X-Amz-Target")
  valid_600872 = validateParameter(valid_600872, JString, required = true, default = newJString(
      "StarlingDoveService.PutConfigurationAggregator"))
  if valid_600872 != nil:
    section.add "X-Amz-Target", valid_600872
  var valid_600873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600873 = validateParameter(valid_600873, JString, required = false,
                                 default = nil)
  if valid_600873 != nil:
    section.add "X-Amz-Content-Sha256", valid_600873
  var valid_600874 = header.getOrDefault("X-Amz-Algorithm")
  valid_600874 = validateParameter(valid_600874, JString, required = false,
                                 default = nil)
  if valid_600874 != nil:
    section.add "X-Amz-Algorithm", valid_600874
  var valid_600875 = header.getOrDefault("X-Amz-Signature")
  valid_600875 = validateParameter(valid_600875, JString, required = false,
                                 default = nil)
  if valid_600875 != nil:
    section.add "X-Amz-Signature", valid_600875
  var valid_600876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600876 = validateParameter(valid_600876, JString, required = false,
                                 default = nil)
  if valid_600876 != nil:
    section.add "X-Amz-SignedHeaders", valid_600876
  var valid_600877 = header.getOrDefault("X-Amz-Credential")
  valid_600877 = validateParameter(valid_600877, JString, required = false,
                                 default = nil)
  if valid_600877 != nil:
    section.add "X-Amz-Credential", valid_600877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600879: Call_PutConfigurationAggregator_600867; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates and updates the configuration aggregator with the selected source accounts and regions. The source account can be individual account(s) or an organization.</p> <note> <p>AWS Config should be enabled in source accounts and regions you want to aggregate.</p> <p>If your source type is an organization, you must be signed in to the master account and all features must be enabled in your organization. AWS Config calls <code>EnableAwsServiceAccess</code> API to enable integration between AWS Config and AWS Organizations. </p> </note>
  ## 
  let valid = call_600879.validator(path, query, header, formData, body)
  let scheme = call_600879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600879.url(scheme.get, call_600879.host, call_600879.base,
                         call_600879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600879, url, valid)

proc call*(call_600880: Call_PutConfigurationAggregator_600867; body: JsonNode): Recallable =
  ## putConfigurationAggregator
  ## <p>Creates and updates the configuration aggregator with the selected source accounts and regions. The source account can be individual account(s) or an organization.</p> <note> <p>AWS Config should be enabled in source accounts and regions you want to aggregate.</p> <p>If your source type is an organization, you must be signed in to the master account and all features must be enabled in your organization. AWS Config calls <code>EnableAwsServiceAccess</code> API to enable integration between AWS Config and AWS Organizations. </p> </note>
  ##   body: JObject (required)
  var body_600881 = newJObject()
  if body != nil:
    body_600881 = body
  result = call_600880.call(nil, nil, nil, nil, body_600881)

var putConfigurationAggregator* = Call_PutConfigurationAggregator_600867(
    name: "putConfigurationAggregator", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutConfigurationAggregator",
    validator: validate_PutConfigurationAggregator_600868, base: "/",
    url: url_PutConfigurationAggregator_600869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationRecorder_600882 = ref object of OpenApiRestCall_599368
proc url_PutConfigurationRecorder_600884(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutConfigurationRecorder_600883(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600885 = header.getOrDefault("X-Amz-Date")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Date", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Security-Token")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Security-Token", valid_600886
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600887 = header.getOrDefault("X-Amz-Target")
  valid_600887 = validateParameter(valid_600887, JString, required = true, default = newJString(
      "StarlingDoveService.PutConfigurationRecorder"))
  if valid_600887 != nil:
    section.add "X-Amz-Target", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Content-Sha256", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Algorithm")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Algorithm", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Signature")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Signature", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-SignedHeaders", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-Credential")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Credential", valid_600892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600894: Call_PutConfigurationRecorder_600882; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new configuration recorder to record the selected resource configurations.</p> <p>You can use this action to change the role <code>roleARN</code> or the <code>recordingGroup</code> of an existing recorder. To change the role, call the action on the existing configuration recorder and specify a role.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> <p>If <code>ConfigurationRecorder</code> does not have the <b>recordingGroup</b> parameter specified, the default is to record all supported resource types.</p> </note>
  ## 
  let valid = call_600894.validator(path, query, header, formData, body)
  let scheme = call_600894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600894.url(scheme.get, call_600894.host, call_600894.base,
                         call_600894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600894, url, valid)

proc call*(call_600895: Call_PutConfigurationRecorder_600882; body: JsonNode): Recallable =
  ## putConfigurationRecorder
  ## <p>Creates a new configuration recorder to record the selected resource configurations.</p> <p>You can use this action to change the role <code>roleARN</code> or the <code>recordingGroup</code> of an existing recorder. To change the role, call the action on the existing configuration recorder and specify a role.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> <p>If <code>ConfigurationRecorder</code> does not have the <b>recordingGroup</b> parameter specified, the default is to record all supported resource types.</p> </note>
  ##   body: JObject (required)
  var body_600896 = newJObject()
  if body != nil:
    body_600896 = body
  result = call_600895.call(nil, nil, nil, nil, body_600896)

var putConfigurationRecorder* = Call_PutConfigurationRecorder_600882(
    name: "putConfigurationRecorder", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutConfigurationRecorder",
    validator: validate_PutConfigurationRecorder_600883, base: "/",
    url: url_PutConfigurationRecorder_600884, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConformancePack_600897 = ref object of OpenApiRestCall_599368
proc url_PutConformancePack_600899(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutConformancePack_600898(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_600900 = header.getOrDefault("X-Amz-Date")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Date", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-Security-Token")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-Security-Token", valid_600901
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600902 = header.getOrDefault("X-Amz-Target")
  valid_600902 = validateParameter(valid_600902, JString, required = true, default = newJString(
      "StarlingDoveService.PutConformancePack"))
  if valid_600902 != nil:
    section.add "X-Amz-Target", valid_600902
  var valid_600903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "X-Amz-Content-Sha256", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-Algorithm")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-Algorithm", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Signature")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Signature", valid_600905
  var valid_600906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-SignedHeaders", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-Credential")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-Credential", valid_600907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600909: Call_PutConformancePack_600897; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates a conformance pack. A conformance pack is a collection of AWS Config rules that can be easily deployed in an account and a region and across AWS Organization.</p> <p>This API creates a service linked role <code>AWSServiceRoleForConfigConforms</code> in your account. The service linked role is created only when the role does not exist in your account. AWS Config verifies the existence of role with <code>GetRole</code> action.</p> <note> <p>You must specify either the <code>TemplateS3Uri</code> or the <code>TemplateBody</code> parameter, but not both. If you provide both AWS Config uses the <code>TemplateS3Uri</code> parameter and ignores the <code>TemplateBody</code> parameter.</p> </note>
  ## 
  let valid = call_600909.validator(path, query, header, formData, body)
  let scheme = call_600909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600909.url(scheme.get, call_600909.host, call_600909.base,
                         call_600909.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600909, url, valid)

proc call*(call_600910: Call_PutConformancePack_600897; body: JsonNode): Recallable =
  ## putConformancePack
  ## <p>Creates or updates a conformance pack. A conformance pack is a collection of AWS Config rules that can be easily deployed in an account and a region and across AWS Organization.</p> <p>This API creates a service linked role <code>AWSServiceRoleForConfigConforms</code> in your account. The service linked role is created only when the role does not exist in your account. AWS Config verifies the existence of role with <code>GetRole</code> action.</p> <note> <p>You must specify either the <code>TemplateS3Uri</code> or the <code>TemplateBody</code> parameter, but not both. If you provide both AWS Config uses the <code>TemplateS3Uri</code> parameter and ignores the <code>TemplateBody</code> parameter.</p> </note>
  ##   body: JObject (required)
  var body_600911 = newJObject()
  if body != nil:
    body_600911 = body
  result = call_600910.call(nil, nil, nil, nil, body_600911)

var putConformancePack* = Call_PutConformancePack_600897(
    name: "putConformancePack", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutConformancePack",
    validator: validate_PutConformancePack_600898, base: "/",
    url: url_PutConformancePack_600899, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDeliveryChannel_600912 = ref object of OpenApiRestCall_599368
proc url_PutDeliveryChannel_600914(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutDeliveryChannel_600913(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_600915 = header.getOrDefault("X-Amz-Date")
  valid_600915 = validateParameter(valid_600915, JString, required = false,
                                 default = nil)
  if valid_600915 != nil:
    section.add "X-Amz-Date", valid_600915
  var valid_600916 = header.getOrDefault("X-Amz-Security-Token")
  valid_600916 = validateParameter(valid_600916, JString, required = false,
                                 default = nil)
  if valid_600916 != nil:
    section.add "X-Amz-Security-Token", valid_600916
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600917 = header.getOrDefault("X-Amz-Target")
  valid_600917 = validateParameter(valid_600917, JString, required = true, default = newJString(
      "StarlingDoveService.PutDeliveryChannel"))
  if valid_600917 != nil:
    section.add "X-Amz-Target", valid_600917
  var valid_600918 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600918 = validateParameter(valid_600918, JString, required = false,
                                 default = nil)
  if valid_600918 != nil:
    section.add "X-Amz-Content-Sha256", valid_600918
  var valid_600919 = header.getOrDefault("X-Amz-Algorithm")
  valid_600919 = validateParameter(valid_600919, JString, required = false,
                                 default = nil)
  if valid_600919 != nil:
    section.add "X-Amz-Algorithm", valid_600919
  var valid_600920 = header.getOrDefault("X-Amz-Signature")
  valid_600920 = validateParameter(valid_600920, JString, required = false,
                                 default = nil)
  if valid_600920 != nil:
    section.add "X-Amz-Signature", valid_600920
  var valid_600921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600921 = validateParameter(valid_600921, JString, required = false,
                                 default = nil)
  if valid_600921 != nil:
    section.add "X-Amz-SignedHeaders", valid_600921
  var valid_600922 = header.getOrDefault("X-Amz-Credential")
  valid_600922 = validateParameter(valid_600922, JString, required = false,
                                 default = nil)
  if valid_600922 != nil:
    section.add "X-Amz-Credential", valid_600922
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600924: Call_PutDeliveryChannel_600912; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a delivery channel object to deliver configuration information to an Amazon S3 bucket and Amazon SNS topic.</p> <p>Before you can create a delivery channel, you must create a configuration recorder.</p> <p>You can use this action to change the Amazon S3 bucket or an Amazon SNS topic of the existing delivery channel. To change the Amazon S3 bucket or an Amazon SNS topic, call this action and specify the changed values for the S3 bucket and the SNS topic. If you specify a different value for either the S3 bucket or the SNS topic, this action will keep the existing value for the parameter that is not changed.</p> <note> <p>You can have only one delivery channel per region in your account.</p> </note>
  ## 
  let valid = call_600924.validator(path, query, header, formData, body)
  let scheme = call_600924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600924.url(scheme.get, call_600924.host, call_600924.base,
                         call_600924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600924, url, valid)

proc call*(call_600925: Call_PutDeliveryChannel_600912; body: JsonNode): Recallable =
  ## putDeliveryChannel
  ## <p>Creates a delivery channel object to deliver configuration information to an Amazon S3 bucket and Amazon SNS topic.</p> <p>Before you can create a delivery channel, you must create a configuration recorder.</p> <p>You can use this action to change the Amazon S3 bucket or an Amazon SNS topic of the existing delivery channel. To change the Amazon S3 bucket or an Amazon SNS topic, call this action and specify the changed values for the S3 bucket and the SNS topic. If you specify a different value for either the S3 bucket or the SNS topic, this action will keep the existing value for the parameter that is not changed.</p> <note> <p>You can have only one delivery channel per region in your account.</p> </note>
  ##   body: JObject (required)
  var body_600926 = newJObject()
  if body != nil:
    body_600926 = body
  result = call_600925.call(nil, nil, nil, nil, body_600926)

var putDeliveryChannel* = Call_PutDeliveryChannel_600912(
    name: "putDeliveryChannel", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutDeliveryChannel",
    validator: validate_PutDeliveryChannel_600913, base: "/",
    url: url_PutDeliveryChannel_600914, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEvaluations_600927 = ref object of OpenApiRestCall_599368
proc url_PutEvaluations_600929(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutEvaluations_600928(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_600930 = header.getOrDefault("X-Amz-Date")
  valid_600930 = validateParameter(valid_600930, JString, required = false,
                                 default = nil)
  if valid_600930 != nil:
    section.add "X-Amz-Date", valid_600930
  var valid_600931 = header.getOrDefault("X-Amz-Security-Token")
  valid_600931 = validateParameter(valid_600931, JString, required = false,
                                 default = nil)
  if valid_600931 != nil:
    section.add "X-Amz-Security-Token", valid_600931
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600932 = header.getOrDefault("X-Amz-Target")
  valid_600932 = validateParameter(valid_600932, JString, required = true, default = newJString(
      "StarlingDoveService.PutEvaluations"))
  if valid_600932 != nil:
    section.add "X-Amz-Target", valid_600932
  var valid_600933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600933 = validateParameter(valid_600933, JString, required = false,
                                 default = nil)
  if valid_600933 != nil:
    section.add "X-Amz-Content-Sha256", valid_600933
  var valid_600934 = header.getOrDefault("X-Amz-Algorithm")
  valid_600934 = validateParameter(valid_600934, JString, required = false,
                                 default = nil)
  if valid_600934 != nil:
    section.add "X-Amz-Algorithm", valid_600934
  var valid_600935 = header.getOrDefault("X-Amz-Signature")
  valid_600935 = validateParameter(valid_600935, JString, required = false,
                                 default = nil)
  if valid_600935 != nil:
    section.add "X-Amz-Signature", valid_600935
  var valid_600936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600936 = validateParameter(valid_600936, JString, required = false,
                                 default = nil)
  if valid_600936 != nil:
    section.add "X-Amz-SignedHeaders", valid_600936
  var valid_600937 = header.getOrDefault("X-Amz-Credential")
  valid_600937 = validateParameter(valid_600937, JString, required = false,
                                 default = nil)
  if valid_600937 != nil:
    section.add "X-Amz-Credential", valid_600937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600939: Call_PutEvaluations_600927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used by an AWS Lambda function to deliver evaluation results to AWS Config. This action is required in every AWS Lambda function that is invoked by an AWS Config rule.
  ## 
  let valid = call_600939.validator(path, query, header, formData, body)
  let scheme = call_600939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600939.url(scheme.get, call_600939.host, call_600939.base,
                         call_600939.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600939, url, valid)

proc call*(call_600940: Call_PutEvaluations_600927; body: JsonNode): Recallable =
  ## putEvaluations
  ## Used by an AWS Lambda function to deliver evaluation results to AWS Config. This action is required in every AWS Lambda function that is invoked by an AWS Config rule.
  ##   body: JObject (required)
  var body_600941 = newJObject()
  if body != nil:
    body_600941 = body
  result = call_600940.call(nil, nil, nil, nil, body_600941)

var putEvaluations* = Call_PutEvaluations_600927(name: "putEvaluations",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutEvaluations",
    validator: validate_PutEvaluations_600928, base: "/", url: url_PutEvaluations_600929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutOrganizationConfigRule_600942 = ref object of OpenApiRestCall_599368
proc url_PutOrganizationConfigRule_600944(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutOrganizationConfigRule_600943(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600945 = header.getOrDefault("X-Amz-Date")
  valid_600945 = validateParameter(valid_600945, JString, required = false,
                                 default = nil)
  if valid_600945 != nil:
    section.add "X-Amz-Date", valid_600945
  var valid_600946 = header.getOrDefault("X-Amz-Security-Token")
  valid_600946 = validateParameter(valid_600946, JString, required = false,
                                 default = nil)
  if valid_600946 != nil:
    section.add "X-Amz-Security-Token", valid_600946
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600947 = header.getOrDefault("X-Amz-Target")
  valid_600947 = validateParameter(valid_600947, JString, required = true, default = newJString(
      "StarlingDoveService.PutOrganizationConfigRule"))
  if valid_600947 != nil:
    section.add "X-Amz-Target", valid_600947
  var valid_600948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600948 = validateParameter(valid_600948, JString, required = false,
                                 default = nil)
  if valid_600948 != nil:
    section.add "X-Amz-Content-Sha256", valid_600948
  var valid_600949 = header.getOrDefault("X-Amz-Algorithm")
  valid_600949 = validateParameter(valid_600949, JString, required = false,
                                 default = nil)
  if valid_600949 != nil:
    section.add "X-Amz-Algorithm", valid_600949
  var valid_600950 = header.getOrDefault("X-Amz-Signature")
  valid_600950 = validateParameter(valid_600950, JString, required = false,
                                 default = nil)
  if valid_600950 != nil:
    section.add "X-Amz-Signature", valid_600950
  var valid_600951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600951 = validateParameter(valid_600951, JString, required = false,
                                 default = nil)
  if valid_600951 != nil:
    section.add "X-Amz-SignedHeaders", valid_600951
  var valid_600952 = header.getOrDefault("X-Amz-Credential")
  valid_600952 = validateParameter(valid_600952, JString, required = false,
                                 default = nil)
  if valid_600952 != nil:
    section.add "X-Amz-Credential", valid_600952
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600954: Call_PutOrganizationConfigRule_600942; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or updates organization config rule for your entire organization evaluating whether your AWS resources comply with your desired configurations. Only a master account can create or update an organization config rule.</p> <p>This API enables organization service access through the <code>EnableAWSServiceAccess</code> action and creates a service linked role <code>AWSServiceRoleForConfigMultiAccountSetup</code> in the master account of your organization. The service linked role is created only when the role does not exist in the master account. AWS Config verifies the existence of role with <code>GetRole</code> action.</p> <p>You can use this action to create both custom AWS Config rules and AWS managed Config rules. If you are adding a new custom AWS Config rule, you must first create AWS Lambda function in the master account that the rule invokes to evaluate your resources. When you use the <code>PutOrganizationConfigRule</code> action to add the rule to AWS Config, you must specify the Amazon Resource Name (ARN) that AWS Lambda assigns to the function. If you are adding an AWS managed Config rule, specify the rule's identifier for the <code>RuleIdentifier</code> key.</p> <p>The maximum number of organization config rules that AWS Config supports is 150.</p> <note> <p>Specify either <code>OrganizationCustomRuleMetadata</code> or <code>OrganizationManagedRuleMetadata</code>.</p> </note>
  ## 
  let valid = call_600954.validator(path, query, header, formData, body)
  let scheme = call_600954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600954.url(scheme.get, call_600954.host, call_600954.base,
                         call_600954.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600954, url, valid)

proc call*(call_600955: Call_PutOrganizationConfigRule_600942; body: JsonNode): Recallable =
  ## putOrganizationConfigRule
  ## <p>Adds or updates organization config rule for your entire organization evaluating whether your AWS resources comply with your desired configurations. Only a master account can create or update an organization config rule.</p> <p>This API enables organization service access through the <code>EnableAWSServiceAccess</code> action and creates a service linked role <code>AWSServiceRoleForConfigMultiAccountSetup</code> in the master account of your organization. The service linked role is created only when the role does not exist in the master account. AWS Config verifies the existence of role with <code>GetRole</code> action.</p> <p>You can use this action to create both custom AWS Config rules and AWS managed Config rules. If you are adding a new custom AWS Config rule, you must first create AWS Lambda function in the master account that the rule invokes to evaluate your resources. When you use the <code>PutOrganizationConfigRule</code> action to add the rule to AWS Config, you must specify the Amazon Resource Name (ARN) that AWS Lambda assigns to the function. If you are adding an AWS managed Config rule, specify the rule's identifier for the <code>RuleIdentifier</code> key.</p> <p>The maximum number of organization config rules that AWS Config supports is 150.</p> <note> <p>Specify either <code>OrganizationCustomRuleMetadata</code> or <code>OrganizationManagedRuleMetadata</code>.</p> </note>
  ##   body: JObject (required)
  var body_600956 = newJObject()
  if body != nil:
    body_600956 = body
  result = call_600955.call(nil, nil, nil, nil, body_600956)

var putOrganizationConfigRule* = Call_PutOrganizationConfigRule_600942(
    name: "putOrganizationConfigRule", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutOrganizationConfigRule",
    validator: validate_PutOrganizationConfigRule_600943, base: "/",
    url: url_PutOrganizationConfigRule_600944,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutOrganizationConformancePack_600957 = ref object of OpenApiRestCall_599368
proc url_PutOrganizationConformancePack_600959(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutOrganizationConformancePack_600958(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600960 = header.getOrDefault("X-Amz-Date")
  valid_600960 = validateParameter(valid_600960, JString, required = false,
                                 default = nil)
  if valid_600960 != nil:
    section.add "X-Amz-Date", valid_600960
  var valid_600961 = header.getOrDefault("X-Amz-Security-Token")
  valid_600961 = validateParameter(valid_600961, JString, required = false,
                                 default = nil)
  if valid_600961 != nil:
    section.add "X-Amz-Security-Token", valid_600961
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600962 = header.getOrDefault("X-Amz-Target")
  valid_600962 = validateParameter(valid_600962, JString, required = true, default = newJString(
      "StarlingDoveService.PutOrganizationConformancePack"))
  if valid_600962 != nil:
    section.add "X-Amz-Target", valid_600962
  var valid_600963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600963 = validateParameter(valid_600963, JString, required = false,
                                 default = nil)
  if valid_600963 != nil:
    section.add "X-Amz-Content-Sha256", valid_600963
  var valid_600964 = header.getOrDefault("X-Amz-Algorithm")
  valid_600964 = validateParameter(valid_600964, JString, required = false,
                                 default = nil)
  if valid_600964 != nil:
    section.add "X-Amz-Algorithm", valid_600964
  var valid_600965 = header.getOrDefault("X-Amz-Signature")
  valid_600965 = validateParameter(valid_600965, JString, required = false,
                                 default = nil)
  if valid_600965 != nil:
    section.add "X-Amz-Signature", valid_600965
  var valid_600966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600966 = validateParameter(valid_600966, JString, required = false,
                                 default = nil)
  if valid_600966 != nil:
    section.add "X-Amz-SignedHeaders", valid_600966
  var valid_600967 = header.getOrDefault("X-Amz-Credential")
  valid_600967 = validateParameter(valid_600967, JString, required = false,
                                 default = nil)
  if valid_600967 != nil:
    section.add "X-Amz-Credential", valid_600967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600969: Call_PutOrganizationConformancePack_600957; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deploys conformance packs across member accounts in an AWS Organization.</p> <p>This API enables organization service access for <code>config-multiaccountsetup.amazonaws.com</code> through the <code>EnableAWSServiceAccess</code> action and creates a service linked role <code>AWSServiceRoleForConfigMultiAccountSetup</code> in the master account of your organization. The service linked role is created only when the role does not exist in the master account. AWS Config verifies the existence of role with GetRole action.</p> <note> <p>You must specify either the <code>TemplateS3Uri</code> or the <code>TemplateBody</code> parameter, but not both. If you provide both AWS Config uses the <code>TemplateS3Uri</code> parameter and ignores the <code>TemplateBody</code> parameter.</p> <p>AWS Config sets the state of a conformance pack to CREATE_IN_PROGRESS and UPDATE_IN_PROGRESS until the confomance pack is created or updated. You cannot update a conformance pack while it is in this state.</p> <p>You can create 6 conformance packs with 25 AWS Config rules in each pack.</p> </note>
  ## 
  let valid = call_600969.validator(path, query, header, formData, body)
  let scheme = call_600969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600969.url(scheme.get, call_600969.host, call_600969.base,
                         call_600969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600969, url, valid)

proc call*(call_600970: Call_PutOrganizationConformancePack_600957; body: JsonNode): Recallable =
  ## putOrganizationConformancePack
  ## <p>Deploys conformance packs across member accounts in an AWS Organization.</p> <p>This API enables organization service access for <code>config-multiaccountsetup.amazonaws.com</code> through the <code>EnableAWSServiceAccess</code> action and creates a service linked role <code>AWSServiceRoleForConfigMultiAccountSetup</code> in the master account of your organization. The service linked role is created only when the role does not exist in the master account. AWS Config verifies the existence of role with GetRole action.</p> <note> <p>You must specify either the <code>TemplateS3Uri</code> or the <code>TemplateBody</code> parameter, but not both. If you provide both AWS Config uses the <code>TemplateS3Uri</code> parameter and ignores the <code>TemplateBody</code> parameter.</p> <p>AWS Config sets the state of a conformance pack to CREATE_IN_PROGRESS and UPDATE_IN_PROGRESS until the confomance pack is created or updated. You cannot update a conformance pack while it is in this state.</p> <p>You can create 6 conformance packs with 25 AWS Config rules in each pack.</p> </note>
  ##   body: JObject (required)
  var body_600971 = newJObject()
  if body != nil:
    body_600971 = body
  result = call_600970.call(nil, nil, nil, nil, body_600971)

var putOrganizationConformancePack* = Call_PutOrganizationConformancePack_600957(
    name: "putOrganizationConformancePack", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutOrganizationConformancePack",
    validator: validate_PutOrganizationConformancePack_600958, base: "/",
    url: url_PutOrganizationConformancePack_600959,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRemediationConfigurations_600972 = ref object of OpenApiRestCall_599368
proc url_PutRemediationConfigurations_600974(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutRemediationConfigurations_600973(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600975 = header.getOrDefault("X-Amz-Date")
  valid_600975 = validateParameter(valid_600975, JString, required = false,
                                 default = nil)
  if valid_600975 != nil:
    section.add "X-Amz-Date", valid_600975
  var valid_600976 = header.getOrDefault("X-Amz-Security-Token")
  valid_600976 = validateParameter(valid_600976, JString, required = false,
                                 default = nil)
  if valid_600976 != nil:
    section.add "X-Amz-Security-Token", valid_600976
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600977 = header.getOrDefault("X-Amz-Target")
  valid_600977 = validateParameter(valid_600977, JString, required = true, default = newJString(
      "StarlingDoveService.PutRemediationConfigurations"))
  if valid_600977 != nil:
    section.add "X-Amz-Target", valid_600977
  var valid_600978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600978 = validateParameter(valid_600978, JString, required = false,
                                 default = nil)
  if valid_600978 != nil:
    section.add "X-Amz-Content-Sha256", valid_600978
  var valid_600979 = header.getOrDefault("X-Amz-Algorithm")
  valid_600979 = validateParameter(valid_600979, JString, required = false,
                                 default = nil)
  if valid_600979 != nil:
    section.add "X-Amz-Algorithm", valid_600979
  var valid_600980 = header.getOrDefault("X-Amz-Signature")
  valid_600980 = validateParameter(valid_600980, JString, required = false,
                                 default = nil)
  if valid_600980 != nil:
    section.add "X-Amz-Signature", valid_600980
  var valid_600981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600981 = validateParameter(valid_600981, JString, required = false,
                                 default = nil)
  if valid_600981 != nil:
    section.add "X-Amz-SignedHeaders", valid_600981
  var valid_600982 = header.getOrDefault("X-Amz-Credential")
  valid_600982 = validateParameter(valid_600982, JString, required = false,
                                 default = nil)
  if valid_600982 != nil:
    section.add "X-Amz-Credential", valid_600982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600984: Call_PutRemediationConfigurations_600972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates the remediation configuration with a specific AWS Config rule with the selected target or action. The API creates the <code>RemediationConfiguration</code> object for the AWS Config rule. The AWS Config rule must already exist for you to add a remediation configuration. The target (SSM document) must exist and have permissions to use the target. 
  ## 
  let valid = call_600984.validator(path, query, header, formData, body)
  let scheme = call_600984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600984.url(scheme.get, call_600984.host, call_600984.base,
                         call_600984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600984, url, valid)

proc call*(call_600985: Call_PutRemediationConfigurations_600972; body: JsonNode): Recallable =
  ## putRemediationConfigurations
  ## Adds or updates the remediation configuration with a specific AWS Config rule with the selected target or action. The API creates the <code>RemediationConfiguration</code> object for the AWS Config rule. The AWS Config rule must already exist for you to add a remediation configuration. The target (SSM document) must exist and have permissions to use the target. 
  ##   body: JObject (required)
  var body_600986 = newJObject()
  if body != nil:
    body_600986 = body
  result = call_600985.call(nil, nil, nil, nil, body_600986)

var putRemediationConfigurations* = Call_PutRemediationConfigurations_600972(
    name: "putRemediationConfigurations", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutRemediationConfigurations",
    validator: validate_PutRemediationConfigurations_600973, base: "/",
    url: url_PutRemediationConfigurations_600974,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRemediationExceptions_600987 = ref object of OpenApiRestCall_599368
proc url_PutRemediationExceptions_600989(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutRemediationExceptions_600988(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600990 = header.getOrDefault("X-Amz-Date")
  valid_600990 = validateParameter(valid_600990, JString, required = false,
                                 default = nil)
  if valid_600990 != nil:
    section.add "X-Amz-Date", valid_600990
  var valid_600991 = header.getOrDefault("X-Amz-Security-Token")
  valid_600991 = validateParameter(valid_600991, JString, required = false,
                                 default = nil)
  if valid_600991 != nil:
    section.add "X-Amz-Security-Token", valid_600991
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600992 = header.getOrDefault("X-Amz-Target")
  valid_600992 = validateParameter(valid_600992, JString, required = true, default = newJString(
      "StarlingDoveService.PutRemediationExceptions"))
  if valid_600992 != nil:
    section.add "X-Amz-Target", valid_600992
  var valid_600993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600993 = validateParameter(valid_600993, JString, required = false,
                                 default = nil)
  if valid_600993 != nil:
    section.add "X-Amz-Content-Sha256", valid_600993
  var valid_600994 = header.getOrDefault("X-Amz-Algorithm")
  valid_600994 = validateParameter(valid_600994, JString, required = false,
                                 default = nil)
  if valid_600994 != nil:
    section.add "X-Amz-Algorithm", valid_600994
  var valid_600995 = header.getOrDefault("X-Amz-Signature")
  valid_600995 = validateParameter(valid_600995, JString, required = false,
                                 default = nil)
  if valid_600995 != nil:
    section.add "X-Amz-Signature", valid_600995
  var valid_600996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600996 = validateParameter(valid_600996, JString, required = false,
                                 default = nil)
  if valid_600996 != nil:
    section.add "X-Amz-SignedHeaders", valid_600996
  var valid_600997 = header.getOrDefault("X-Amz-Credential")
  valid_600997 = validateParameter(valid_600997, JString, required = false,
                                 default = nil)
  if valid_600997 != nil:
    section.add "X-Amz-Credential", valid_600997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600999: Call_PutRemediationExceptions_600987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A remediation exception is when a specific resource is no longer considered for auto-remediation. This API adds a new exception or updates an exisiting exception for a specific resource with a specific AWS Config rule. 
  ## 
  let valid = call_600999.validator(path, query, header, formData, body)
  let scheme = call_600999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600999.url(scheme.get, call_600999.host, call_600999.base,
                         call_600999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600999, url, valid)

proc call*(call_601000: Call_PutRemediationExceptions_600987; body: JsonNode): Recallable =
  ## putRemediationExceptions
  ## A remediation exception is when a specific resource is no longer considered for auto-remediation. This API adds a new exception or updates an exisiting exception for a specific resource with a specific AWS Config rule. 
  ##   body: JObject (required)
  var body_601001 = newJObject()
  if body != nil:
    body_601001 = body
  result = call_601000.call(nil, nil, nil, nil, body_601001)

var putRemediationExceptions* = Call_PutRemediationExceptions_600987(
    name: "putRemediationExceptions", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutRemediationExceptions",
    validator: validate_PutRemediationExceptions_600988, base: "/",
    url: url_PutRemediationExceptions_600989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourceConfig_601002 = ref object of OpenApiRestCall_599368
proc url_PutResourceConfig_601004(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutResourceConfig_601003(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_601005 = header.getOrDefault("X-Amz-Date")
  valid_601005 = validateParameter(valid_601005, JString, required = false,
                                 default = nil)
  if valid_601005 != nil:
    section.add "X-Amz-Date", valid_601005
  var valid_601006 = header.getOrDefault("X-Amz-Security-Token")
  valid_601006 = validateParameter(valid_601006, JString, required = false,
                                 default = nil)
  if valid_601006 != nil:
    section.add "X-Amz-Security-Token", valid_601006
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601007 = header.getOrDefault("X-Amz-Target")
  valid_601007 = validateParameter(valid_601007, JString, required = true, default = newJString(
      "StarlingDoveService.PutResourceConfig"))
  if valid_601007 != nil:
    section.add "X-Amz-Target", valid_601007
  var valid_601008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601008 = validateParameter(valid_601008, JString, required = false,
                                 default = nil)
  if valid_601008 != nil:
    section.add "X-Amz-Content-Sha256", valid_601008
  var valid_601009 = header.getOrDefault("X-Amz-Algorithm")
  valid_601009 = validateParameter(valid_601009, JString, required = false,
                                 default = nil)
  if valid_601009 != nil:
    section.add "X-Amz-Algorithm", valid_601009
  var valid_601010 = header.getOrDefault("X-Amz-Signature")
  valid_601010 = validateParameter(valid_601010, JString, required = false,
                                 default = nil)
  if valid_601010 != nil:
    section.add "X-Amz-Signature", valid_601010
  var valid_601011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601011 = validateParameter(valid_601011, JString, required = false,
                                 default = nil)
  if valid_601011 != nil:
    section.add "X-Amz-SignedHeaders", valid_601011
  var valid_601012 = header.getOrDefault("X-Amz-Credential")
  valid_601012 = validateParameter(valid_601012, JString, required = false,
                                 default = nil)
  if valid_601012 != nil:
    section.add "X-Amz-Credential", valid_601012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601014: Call_PutResourceConfig_601002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Records the configuration state for the resource provided in the request. The configuration state of a resource is represented in AWS Config as Configuration Items. Once this API records the configuration item, you can retrieve the list of configuration items for the custom resource type using existing AWS Config APIs. </p> <note> <p>The custom resource type must be registered with AWS CloudFormation. This API accepts the configuration item registered with AWS CloudFormation.</p> <p>When you call this API, AWS Config only stores configuration state of the resource provided in the request. This API does not change or remediate the configuration of the resource. </p> </note>
  ## 
  let valid = call_601014.validator(path, query, header, formData, body)
  let scheme = call_601014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601014.url(scheme.get, call_601014.host, call_601014.base,
                         call_601014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601014, url, valid)

proc call*(call_601015: Call_PutResourceConfig_601002; body: JsonNode): Recallable =
  ## putResourceConfig
  ## <p>Records the configuration state for the resource provided in the request. The configuration state of a resource is represented in AWS Config as Configuration Items. Once this API records the configuration item, you can retrieve the list of configuration items for the custom resource type using existing AWS Config APIs. </p> <note> <p>The custom resource type must be registered with AWS CloudFormation. This API accepts the configuration item registered with AWS CloudFormation.</p> <p>When you call this API, AWS Config only stores configuration state of the resource provided in the request. This API does not change or remediate the configuration of the resource. </p> </note>
  ##   body: JObject (required)
  var body_601016 = newJObject()
  if body != nil:
    body_601016 = body
  result = call_601015.call(nil, nil, nil, nil, body_601016)

var putResourceConfig* = Call_PutResourceConfig_601002(name: "putResourceConfig",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutResourceConfig",
    validator: validate_PutResourceConfig_601003, base: "/",
    url: url_PutResourceConfig_601004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRetentionConfiguration_601017 = ref object of OpenApiRestCall_599368
proc url_PutRetentionConfiguration_601019(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutRetentionConfiguration_601018(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601020 = header.getOrDefault("X-Amz-Date")
  valid_601020 = validateParameter(valid_601020, JString, required = false,
                                 default = nil)
  if valid_601020 != nil:
    section.add "X-Amz-Date", valid_601020
  var valid_601021 = header.getOrDefault("X-Amz-Security-Token")
  valid_601021 = validateParameter(valid_601021, JString, required = false,
                                 default = nil)
  if valid_601021 != nil:
    section.add "X-Amz-Security-Token", valid_601021
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601022 = header.getOrDefault("X-Amz-Target")
  valid_601022 = validateParameter(valid_601022, JString, required = true, default = newJString(
      "StarlingDoveService.PutRetentionConfiguration"))
  if valid_601022 != nil:
    section.add "X-Amz-Target", valid_601022
  var valid_601023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601023 = validateParameter(valid_601023, JString, required = false,
                                 default = nil)
  if valid_601023 != nil:
    section.add "X-Amz-Content-Sha256", valid_601023
  var valid_601024 = header.getOrDefault("X-Amz-Algorithm")
  valid_601024 = validateParameter(valid_601024, JString, required = false,
                                 default = nil)
  if valid_601024 != nil:
    section.add "X-Amz-Algorithm", valid_601024
  var valid_601025 = header.getOrDefault("X-Amz-Signature")
  valid_601025 = validateParameter(valid_601025, JString, required = false,
                                 default = nil)
  if valid_601025 != nil:
    section.add "X-Amz-Signature", valid_601025
  var valid_601026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601026 = validateParameter(valid_601026, JString, required = false,
                                 default = nil)
  if valid_601026 != nil:
    section.add "X-Amz-SignedHeaders", valid_601026
  var valid_601027 = header.getOrDefault("X-Amz-Credential")
  valid_601027 = validateParameter(valid_601027, JString, required = false,
                                 default = nil)
  if valid_601027 != nil:
    section.add "X-Amz-Credential", valid_601027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601029: Call_PutRetentionConfiguration_601017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates and updates the retention configuration with details about retention period (number of days) that AWS Config stores your historical information. The API creates the <code>RetentionConfiguration</code> object and names the object as <b>default</b>. When you have a <code>RetentionConfiguration</code> object named <b>default</b>, calling the API modifies the default object. </p> <note> <p>Currently, AWS Config supports only one retention configuration per region in your account.</p> </note>
  ## 
  let valid = call_601029.validator(path, query, header, formData, body)
  let scheme = call_601029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601029.url(scheme.get, call_601029.host, call_601029.base,
                         call_601029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601029, url, valid)

proc call*(call_601030: Call_PutRetentionConfiguration_601017; body: JsonNode): Recallable =
  ## putRetentionConfiguration
  ## <p>Creates and updates the retention configuration with details about retention period (number of days) that AWS Config stores your historical information. The API creates the <code>RetentionConfiguration</code> object and names the object as <b>default</b>. When you have a <code>RetentionConfiguration</code> object named <b>default</b>, calling the API modifies the default object. </p> <note> <p>Currently, AWS Config supports only one retention configuration per region in your account.</p> </note>
  ##   body: JObject (required)
  var body_601031 = newJObject()
  if body != nil:
    body_601031 = body
  result = call_601030.call(nil, nil, nil, nil, body_601031)

var putRetentionConfiguration* = Call_PutRetentionConfiguration_601017(
    name: "putRetentionConfiguration", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutRetentionConfiguration",
    validator: validate_PutRetentionConfiguration_601018, base: "/",
    url: url_PutRetentionConfiguration_601019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SelectResourceConfig_601032 = ref object of OpenApiRestCall_599368
proc url_SelectResourceConfig_601034(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SelectResourceConfig_601033(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601035 = header.getOrDefault("X-Amz-Date")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "X-Amz-Date", valid_601035
  var valid_601036 = header.getOrDefault("X-Amz-Security-Token")
  valid_601036 = validateParameter(valid_601036, JString, required = false,
                                 default = nil)
  if valid_601036 != nil:
    section.add "X-Amz-Security-Token", valid_601036
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601037 = header.getOrDefault("X-Amz-Target")
  valid_601037 = validateParameter(valid_601037, JString, required = true, default = newJString(
      "StarlingDoveService.SelectResourceConfig"))
  if valid_601037 != nil:
    section.add "X-Amz-Target", valid_601037
  var valid_601038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601038 = validateParameter(valid_601038, JString, required = false,
                                 default = nil)
  if valid_601038 != nil:
    section.add "X-Amz-Content-Sha256", valid_601038
  var valid_601039 = header.getOrDefault("X-Amz-Algorithm")
  valid_601039 = validateParameter(valid_601039, JString, required = false,
                                 default = nil)
  if valid_601039 != nil:
    section.add "X-Amz-Algorithm", valid_601039
  var valid_601040 = header.getOrDefault("X-Amz-Signature")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Signature", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-SignedHeaders", valid_601041
  var valid_601042 = header.getOrDefault("X-Amz-Credential")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Credential", valid_601042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601044: Call_SelectResourceConfig_601032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Accepts a structured query language (SQL) <code>SELECT</code> command, performs the corresponding search, and returns resource configurations matching the properties.</p> <p>For more information about query components, see the <a href="https://docs.aws.amazon.com/config/latest/developerguide/query-components.html"> <b>Query Components</b> </a> section in the AWS Config Developer Guide.</p>
  ## 
  let valid = call_601044.validator(path, query, header, formData, body)
  let scheme = call_601044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601044.url(scheme.get, call_601044.host, call_601044.base,
                         call_601044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601044, url, valid)

proc call*(call_601045: Call_SelectResourceConfig_601032; body: JsonNode): Recallable =
  ## selectResourceConfig
  ## <p>Accepts a structured query language (SQL) <code>SELECT</code> command, performs the corresponding search, and returns resource configurations matching the properties.</p> <p>For more information about query components, see the <a href="https://docs.aws.amazon.com/config/latest/developerguide/query-components.html"> <b>Query Components</b> </a> section in the AWS Config Developer Guide.</p>
  ##   body: JObject (required)
  var body_601046 = newJObject()
  if body != nil:
    body_601046 = body
  result = call_601045.call(nil, nil, nil, nil, body_601046)

var selectResourceConfig* = Call_SelectResourceConfig_601032(
    name: "selectResourceConfig", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.SelectResourceConfig",
    validator: validate_SelectResourceConfig_601033, base: "/",
    url: url_SelectResourceConfig_601034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartConfigRulesEvaluation_601047 = ref object of OpenApiRestCall_599368
proc url_StartConfigRulesEvaluation_601049(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartConfigRulesEvaluation_601048(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601050 = header.getOrDefault("X-Amz-Date")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Date", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-Security-Token")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Security-Token", valid_601051
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601052 = header.getOrDefault("X-Amz-Target")
  valid_601052 = validateParameter(valid_601052, JString, required = true, default = newJString(
      "StarlingDoveService.StartConfigRulesEvaluation"))
  if valid_601052 != nil:
    section.add "X-Amz-Target", valid_601052
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

proc call*(call_601059: Call_StartConfigRulesEvaluation_601047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs an on-demand evaluation for the specified AWS Config rules against the last known configuration state of the resources. Use <code>StartConfigRulesEvaluation</code> when you want to test that a rule you updated is working as expected. <code>StartConfigRulesEvaluation</code> does not re-record the latest configuration state for your resources. It re-runs an evaluation against the last known state of your resources. </p> <p>You can specify up to 25 AWS Config rules per request. </p> <p>An existing <code>StartConfigRulesEvaluation</code> call for the specified rules must complete before you can call the API again. If you chose to have AWS Config stream to an Amazon SNS topic, you will receive a <code>ConfigRuleEvaluationStarted</code> notification when the evaluation starts.</p> <note> <p>You don't need to call the <code>StartConfigRulesEvaluation</code> API to run an evaluation for a new rule. When you create a rule, AWS Config evaluates your resources against the rule automatically. </p> </note> <p>The <code>StartConfigRulesEvaluation</code> API is useful if you want to run on-demand evaluations, such as the following example:</p> <ol> <li> <p>You have a custom rule that evaluates your IAM resources every 24 hours.</p> </li> <li> <p>You update your Lambda function to add additional conditions to your rule.</p> </li> <li> <p>Instead of waiting for the next periodic evaluation, you call the <code>StartConfigRulesEvaluation</code> API.</p> </li> <li> <p>AWS Config invokes your Lambda function and evaluates your IAM resources.</p> </li> <li> <p>Your custom rule will still run periodic evaluations every 24 hours.</p> </li> </ol>
  ## 
  let valid = call_601059.validator(path, query, header, formData, body)
  let scheme = call_601059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601059.url(scheme.get, call_601059.host, call_601059.base,
                         call_601059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601059, url, valid)

proc call*(call_601060: Call_StartConfigRulesEvaluation_601047; body: JsonNode): Recallable =
  ## startConfigRulesEvaluation
  ## <p>Runs an on-demand evaluation for the specified AWS Config rules against the last known configuration state of the resources. Use <code>StartConfigRulesEvaluation</code> when you want to test that a rule you updated is working as expected. <code>StartConfigRulesEvaluation</code> does not re-record the latest configuration state for your resources. It re-runs an evaluation against the last known state of your resources. </p> <p>You can specify up to 25 AWS Config rules per request. </p> <p>An existing <code>StartConfigRulesEvaluation</code> call for the specified rules must complete before you can call the API again. If you chose to have AWS Config stream to an Amazon SNS topic, you will receive a <code>ConfigRuleEvaluationStarted</code> notification when the evaluation starts.</p> <note> <p>You don't need to call the <code>StartConfigRulesEvaluation</code> API to run an evaluation for a new rule. When you create a rule, AWS Config evaluates your resources against the rule automatically. </p> </note> <p>The <code>StartConfigRulesEvaluation</code> API is useful if you want to run on-demand evaluations, such as the following example:</p> <ol> <li> <p>You have a custom rule that evaluates your IAM resources every 24 hours.</p> </li> <li> <p>You update your Lambda function to add additional conditions to your rule.</p> </li> <li> <p>Instead of waiting for the next periodic evaluation, you call the <code>StartConfigRulesEvaluation</code> API.</p> </li> <li> <p>AWS Config invokes your Lambda function and evaluates your IAM resources.</p> </li> <li> <p>Your custom rule will still run periodic evaluations every 24 hours.</p> </li> </ol>
  ##   body: JObject (required)
  var body_601061 = newJObject()
  if body != nil:
    body_601061 = body
  result = call_601060.call(nil, nil, nil, nil, body_601061)

var startConfigRulesEvaluation* = Call_StartConfigRulesEvaluation_601047(
    name: "startConfigRulesEvaluation", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.StartConfigRulesEvaluation",
    validator: validate_StartConfigRulesEvaluation_601048, base: "/",
    url: url_StartConfigRulesEvaluation_601049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartConfigurationRecorder_601062 = ref object of OpenApiRestCall_599368
proc url_StartConfigurationRecorder_601064(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartConfigurationRecorder_601063(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601065 = header.getOrDefault("X-Amz-Date")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Date", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-Security-Token")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Security-Token", valid_601066
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601067 = header.getOrDefault("X-Amz-Target")
  valid_601067 = validateParameter(valid_601067, JString, required = true, default = newJString(
      "StarlingDoveService.StartConfigurationRecorder"))
  if valid_601067 != nil:
    section.add "X-Amz-Target", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Content-Sha256", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Algorithm")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Algorithm", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-Signature")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Signature", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-SignedHeaders", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Credential")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Credential", valid_601072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601074: Call_StartConfigurationRecorder_601062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts recording configurations of the AWS resources you have selected to record in your AWS account.</p> <p>You must have created at least one delivery channel to successfully start the configuration recorder.</p>
  ## 
  let valid = call_601074.validator(path, query, header, formData, body)
  let scheme = call_601074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601074.url(scheme.get, call_601074.host, call_601074.base,
                         call_601074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601074, url, valid)

proc call*(call_601075: Call_StartConfigurationRecorder_601062; body: JsonNode): Recallable =
  ## startConfigurationRecorder
  ## <p>Starts recording configurations of the AWS resources you have selected to record in your AWS account.</p> <p>You must have created at least one delivery channel to successfully start the configuration recorder.</p>
  ##   body: JObject (required)
  var body_601076 = newJObject()
  if body != nil:
    body_601076 = body
  result = call_601075.call(nil, nil, nil, nil, body_601076)

var startConfigurationRecorder* = Call_StartConfigurationRecorder_601062(
    name: "startConfigurationRecorder", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.StartConfigurationRecorder",
    validator: validate_StartConfigurationRecorder_601063, base: "/",
    url: url_StartConfigurationRecorder_601064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartRemediationExecution_601077 = ref object of OpenApiRestCall_599368
proc url_StartRemediationExecution_601079(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartRemediationExecution_601078(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601080 = header.getOrDefault("X-Amz-Date")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Date", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-Security-Token")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Security-Token", valid_601081
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601082 = header.getOrDefault("X-Amz-Target")
  valid_601082 = validateParameter(valid_601082, JString, required = true, default = newJString(
      "StarlingDoveService.StartRemediationExecution"))
  if valid_601082 != nil:
    section.add "X-Amz-Target", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Content-Sha256", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Algorithm")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Algorithm", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Signature")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Signature", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-SignedHeaders", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-Credential")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Credential", valid_601087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601089: Call_StartRemediationExecution_601077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs an on-demand remediation for the specified AWS Config rules against the last known remediation configuration. It runs an execution against the current state of your resources. Remediation execution is asynchronous.</p> <p>You can specify up to 100 resource keys per request. An existing StartRemediationExecution call for the specified resource keys must complete before you can call the API again.</p>
  ## 
  let valid = call_601089.validator(path, query, header, formData, body)
  let scheme = call_601089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601089.url(scheme.get, call_601089.host, call_601089.base,
                         call_601089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601089, url, valid)

proc call*(call_601090: Call_StartRemediationExecution_601077; body: JsonNode): Recallable =
  ## startRemediationExecution
  ## <p>Runs an on-demand remediation for the specified AWS Config rules against the last known remediation configuration. It runs an execution against the current state of your resources. Remediation execution is asynchronous.</p> <p>You can specify up to 100 resource keys per request. An existing StartRemediationExecution call for the specified resource keys must complete before you can call the API again.</p>
  ##   body: JObject (required)
  var body_601091 = newJObject()
  if body != nil:
    body_601091 = body
  result = call_601090.call(nil, nil, nil, nil, body_601091)

var startRemediationExecution* = Call_StartRemediationExecution_601077(
    name: "startRemediationExecution", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.StartRemediationExecution",
    validator: validate_StartRemediationExecution_601078, base: "/",
    url: url_StartRemediationExecution_601079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopConfigurationRecorder_601092 = ref object of OpenApiRestCall_599368
proc url_StopConfigurationRecorder_601094(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopConfigurationRecorder_601093(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601095 = header.getOrDefault("X-Amz-Date")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Date", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Security-Token")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Security-Token", valid_601096
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601097 = header.getOrDefault("X-Amz-Target")
  valid_601097 = validateParameter(valid_601097, JString, required = true, default = newJString(
      "StarlingDoveService.StopConfigurationRecorder"))
  if valid_601097 != nil:
    section.add "X-Amz-Target", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-Content-Sha256", valid_601098
  var valid_601099 = header.getOrDefault("X-Amz-Algorithm")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Algorithm", valid_601099
  var valid_601100 = header.getOrDefault("X-Amz-Signature")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Signature", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-SignedHeaders", valid_601101
  var valid_601102 = header.getOrDefault("X-Amz-Credential")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Credential", valid_601102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601104: Call_StopConfigurationRecorder_601092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops recording configurations of the AWS resources you have selected to record in your AWS account.
  ## 
  let valid = call_601104.validator(path, query, header, formData, body)
  let scheme = call_601104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601104.url(scheme.get, call_601104.host, call_601104.base,
                         call_601104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601104, url, valid)

proc call*(call_601105: Call_StopConfigurationRecorder_601092; body: JsonNode): Recallable =
  ## stopConfigurationRecorder
  ## Stops recording configurations of the AWS resources you have selected to record in your AWS account.
  ##   body: JObject (required)
  var body_601106 = newJObject()
  if body != nil:
    body_601106 = body
  result = call_601105.call(nil, nil, nil, nil, body_601106)

var stopConfigurationRecorder* = Call_StopConfigurationRecorder_601092(
    name: "stopConfigurationRecorder", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.StopConfigurationRecorder",
    validator: validate_StopConfigurationRecorder_601093, base: "/",
    url: url_StopConfigurationRecorder_601094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601107 = ref object of OpenApiRestCall_599368
proc url_TagResource_601109(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_601108(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601110 = header.getOrDefault("X-Amz-Date")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Date", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Security-Token")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Security-Token", valid_601111
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601112 = header.getOrDefault("X-Amz-Target")
  valid_601112 = validateParameter(valid_601112, JString, required = true, default = newJString(
      "StarlingDoveService.TagResource"))
  if valid_601112 != nil:
    section.add "X-Amz-Target", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-Content-Sha256", valid_601113
  var valid_601114 = header.getOrDefault("X-Amz-Algorithm")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Algorithm", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-Signature")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Signature", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-SignedHeaders", valid_601116
  var valid_601117 = header.getOrDefault("X-Amz-Credential")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-Credential", valid_601117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601119: Call_TagResource_601107; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ## 
  let valid = call_601119.validator(path, query, header, formData, body)
  let scheme = call_601119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601119.url(scheme.get, call_601119.host, call_601119.base,
                         call_601119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601119, url, valid)

proc call*(call_601120: Call_TagResource_601107; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ##   body: JObject (required)
  var body_601121 = newJObject()
  if body != nil:
    body_601121 = body
  result = call_601120.call(nil, nil, nil, nil, body_601121)

var tagResource* = Call_TagResource_601107(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.TagResource",
                                        validator: validate_TagResource_601108,
                                        base: "/", url: url_TagResource_601109,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601122 = ref object of OpenApiRestCall_599368
proc url_UntagResource_601124(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_601123(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601125 = header.getOrDefault("X-Amz-Date")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Date", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Security-Token")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Security-Token", valid_601126
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601127 = header.getOrDefault("X-Amz-Target")
  valid_601127 = validateParameter(valid_601127, JString, required = true, default = newJString(
      "StarlingDoveService.UntagResource"))
  if valid_601127 != nil:
    section.add "X-Amz-Target", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Content-Sha256", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-Algorithm")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Algorithm", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-Signature")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Signature", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-SignedHeaders", valid_601131
  var valid_601132 = header.getOrDefault("X-Amz-Credential")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-Credential", valid_601132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601134: Call_UntagResource_601122; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_601134.validator(path, query, header, formData, body)
  let scheme = call_601134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601134.url(scheme.get, call_601134.host, call_601134.base,
                         call_601134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601134, url, valid)

proc call*(call_601135: Call_UntagResource_601122; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   body: JObject (required)
  var body_601136 = newJObject()
  if body != nil:
    body_601136 = body
  result = call_601135.call(nil, nil, nil, nil, body_601136)

var untagResource* = Call_UntagResource_601122(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.UntagResource",
    validator: validate_UntagResource_601123, base: "/", url: url_UntagResource_601124,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
