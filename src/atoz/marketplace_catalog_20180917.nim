
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Marketplace Catalog Service
## version: 2018-09-17
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Catalog API actions allow you to create, describe, list, and delete changes to your published entities. An entity is a product or an offer on AWS Marketplace.</p> <p>You can automate your entity update process by integrating the AWS Marketplace Catalog API with your AWS Marketplace product build or deployment pipelines. You can also create your own applications on top of the Catalog API to manage your products on AWS Marketplace.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/marketplace/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "catalog.marketplace.ap-northeast-1.amazonaws.com", "ap-southeast-1": "catalog.marketplace.ap-southeast-1.amazonaws.com", "us-west-2": "catalog.marketplace.us-west-2.amazonaws.com", "eu-west-2": "catalog.marketplace.eu-west-2.amazonaws.com", "ap-northeast-3": "catalog.marketplace.ap-northeast-3.amazonaws.com", "eu-central-1": "catalog.marketplace.eu-central-1.amazonaws.com", "us-east-2": "catalog.marketplace.us-east-2.amazonaws.com", "us-east-1": "catalog.marketplace.us-east-1.amazonaws.com", "cn-northwest-1": "catalog.marketplace.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "catalog.marketplace.ap-south-1.amazonaws.com", "eu-north-1": "catalog.marketplace.eu-north-1.amazonaws.com", "ap-northeast-2": "catalog.marketplace.ap-northeast-2.amazonaws.com", "us-west-1": "catalog.marketplace.us-west-1.amazonaws.com", "us-gov-east-1": "catalog.marketplace.us-gov-east-1.amazonaws.com", "eu-west-3": "catalog.marketplace.eu-west-3.amazonaws.com", "cn-north-1": "catalog.marketplace.cn-north-1.amazonaws.com.cn", "sa-east-1": "catalog.marketplace.sa-east-1.amazonaws.com", "eu-west-1": "catalog.marketplace.eu-west-1.amazonaws.com", "us-gov-west-1": "catalog.marketplace.us-gov-west-1.amazonaws.com", "ap-southeast-2": "catalog.marketplace.ap-southeast-2.amazonaws.com", "ca-central-1": "catalog.marketplace.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "catalog.marketplace.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "catalog.marketplace.ap-southeast-1.amazonaws.com",
      "us-west-2": "catalog.marketplace.us-west-2.amazonaws.com",
      "eu-west-2": "catalog.marketplace.eu-west-2.amazonaws.com",
      "ap-northeast-3": "catalog.marketplace.ap-northeast-3.amazonaws.com",
      "eu-central-1": "catalog.marketplace.eu-central-1.amazonaws.com",
      "us-east-2": "catalog.marketplace.us-east-2.amazonaws.com",
      "us-east-1": "catalog.marketplace.us-east-1.amazonaws.com",
      "cn-northwest-1": "catalog.marketplace.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "catalog.marketplace.ap-south-1.amazonaws.com",
      "eu-north-1": "catalog.marketplace.eu-north-1.amazonaws.com",
      "ap-northeast-2": "catalog.marketplace.ap-northeast-2.amazonaws.com",
      "us-west-1": "catalog.marketplace.us-west-1.amazonaws.com",
      "us-gov-east-1": "catalog.marketplace.us-gov-east-1.amazonaws.com",
      "eu-west-3": "catalog.marketplace.eu-west-3.amazonaws.com",
      "cn-north-1": "catalog.marketplace.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "catalog.marketplace.sa-east-1.amazonaws.com",
      "eu-west-1": "catalog.marketplace.eu-west-1.amazonaws.com",
      "us-gov-west-1": "catalog.marketplace.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "catalog.marketplace.ap-southeast-2.amazonaws.com",
      "ca-central-1": "catalog.marketplace.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "marketplace-catalog"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CancelChangeSet_21625779 = ref object of OpenApiRestCall_21625435
proc url_CancelChangeSet_21625781(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelChangeSet_21625780(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Used to cancel an open change request. Must be sent before the status of the request changes to <code>APPLYING</code>, the final stage of completing your change request. You can describe a change during the 60-day request history retention period for API calls.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   catalog: JString (required)
  ##          : Required. The catalog related to the request. Fixed value: <code>AWSMarketplace</code>.
  ##   changeSetId: JString (required)
  ##              : Required. The unique identifier of the <code>StartChangeSet</code> request that you want to cancel.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `catalog` field"
  var valid_21625882 = query.getOrDefault("catalog")
  valid_21625882 = validateParameter(valid_21625882, JString, required = true,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "catalog", valid_21625882
  var valid_21625883 = query.getOrDefault("changeSetId")
  valid_21625883 = validateParameter(valid_21625883, JString, required = true,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "changeSetId", valid_21625883
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
  var valid_21625884 = header.getOrDefault("X-Amz-Date")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "X-Amz-Date", valid_21625884
  var valid_21625885 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "X-Amz-Security-Token", valid_21625885
  var valid_21625886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625886 = validateParameter(valid_21625886, JString, required = false,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625886
  var valid_21625887 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625887 = validateParameter(valid_21625887, JString, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "X-Amz-Algorithm", valid_21625887
  var valid_21625888 = header.getOrDefault("X-Amz-Signature")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-Signature", valid_21625888
  var valid_21625889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625889 = validateParameter(valid_21625889, JString, required = false,
                                   default = nil)
  if valid_21625889 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625889
  var valid_21625890 = header.getOrDefault("X-Amz-Credential")
  valid_21625890 = validateParameter(valid_21625890, JString, required = false,
                                   default = nil)
  if valid_21625890 != nil:
    section.add "X-Amz-Credential", valid_21625890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625915: Call_CancelChangeSet_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Used to cancel an open change request. Must be sent before the status of the request changes to <code>APPLYING</code>, the final stage of completing your change request. You can describe a change during the 60-day request history retention period for API calls.
  ## 
  let valid = call_21625915.validator(path, query, header, formData, body, _)
  let scheme = call_21625915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625915.makeUrl(scheme.get, call_21625915.host, call_21625915.base,
                               call_21625915.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625915, uri, valid, _)

proc call*(call_21625978: Call_CancelChangeSet_21625779; catalog: string;
          changeSetId: string): Recallable =
  ## cancelChangeSet
  ## Used to cancel an open change request. Must be sent before the status of the request changes to <code>APPLYING</code>, the final stage of completing your change request. You can describe a change during the 60-day request history retention period for API calls.
  ##   catalog: string (required)
  ##          : Required. The catalog related to the request. Fixed value: <code>AWSMarketplace</code>.
  ##   changeSetId: string (required)
  ##              : Required. The unique identifier of the <code>StartChangeSet</code> request that you want to cancel.
  var query_21625980 = newJObject()
  add(query_21625980, "catalog", newJString(catalog))
  add(query_21625980, "changeSetId", newJString(changeSetId))
  result = call_21625978.call(nil, query_21625980, nil, nil, nil)

var cancelChangeSet* = Call_CancelChangeSet_21625779(name: "cancelChangeSet",
    meth: HttpMethod.HttpPatch, host: "catalog.marketplace.amazonaws.com",
    route: "/CancelChangeSet#catalog&changeSetId",
    validator: validate_CancelChangeSet_21625780, base: "/",
    makeUrl: url_CancelChangeSet_21625781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChangeSet_21626018 = ref object of OpenApiRestCall_21625435
proc url_DescribeChangeSet_21626020(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeChangeSet_21626019(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides information about a given change set.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   catalog: JString (required)
  ##          : Required. The catalog related to the request. Fixed value: <code>AWSMarketplace</code> 
  ##   changeSetId: JString (required)
  ##              : Required. The unique identifier for the <code>StartChangeSet</code> request that you want to describe the details for.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `catalog` field"
  var valid_21626021 = query.getOrDefault("catalog")
  valid_21626021 = validateParameter(valid_21626021, JString, required = true,
                                   default = nil)
  if valid_21626021 != nil:
    section.add "catalog", valid_21626021
  var valid_21626022 = query.getOrDefault("changeSetId")
  valid_21626022 = validateParameter(valid_21626022, JString, required = true,
                                   default = nil)
  if valid_21626022 != nil:
    section.add "changeSetId", valid_21626022
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
  var valid_21626023 = header.getOrDefault("X-Amz-Date")
  valid_21626023 = validateParameter(valid_21626023, JString, required = false,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "X-Amz-Date", valid_21626023
  var valid_21626024 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626024 = validateParameter(valid_21626024, JString, required = false,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "X-Amz-Security-Token", valid_21626024
  var valid_21626025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626025 = validateParameter(valid_21626025, JString, required = false,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626025
  var valid_21626026 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Algorithm", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-Signature")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-Signature", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626028
  var valid_21626029 = header.getOrDefault("X-Amz-Credential")
  valid_21626029 = validateParameter(valid_21626029, JString, required = false,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "X-Amz-Credential", valid_21626029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626030: Call_DescribeChangeSet_21626018; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides information about a given change set.
  ## 
  let valid = call_21626030.validator(path, query, header, formData, body, _)
  let scheme = call_21626030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626030.makeUrl(scheme.get, call_21626030.host, call_21626030.base,
                               call_21626030.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626030, uri, valid, _)

proc call*(call_21626031: Call_DescribeChangeSet_21626018; catalog: string;
          changeSetId: string): Recallable =
  ## describeChangeSet
  ## Provides information about a given change set.
  ##   catalog: string (required)
  ##          : Required. The catalog related to the request. Fixed value: <code>AWSMarketplace</code> 
  ##   changeSetId: string (required)
  ##              : Required. The unique identifier for the <code>StartChangeSet</code> request that you want to describe the details for.
  var query_21626032 = newJObject()
  add(query_21626032, "catalog", newJString(catalog))
  add(query_21626032, "changeSetId", newJString(changeSetId))
  result = call_21626031.call(nil, query_21626032, nil, nil, nil)

var describeChangeSet* = Call_DescribeChangeSet_21626018(name: "describeChangeSet",
    meth: HttpMethod.HttpGet, host: "catalog.marketplace.amazonaws.com",
    route: "/DescribeChangeSet#catalog&changeSetId",
    validator: validate_DescribeChangeSet_21626019, base: "/",
    makeUrl: url_DescribeChangeSet_21626020, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEntity_21626033 = ref object of OpenApiRestCall_21625435
proc url_DescribeEntity_21626035(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEntity_21626034(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the metadata and content of the entity.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   entityId: JString (required)
  ##           : Required. The unique ID of the entity to describe.
  ##   catalog: JString (required)
  ##          : Required. The catalog related to the request. Fixed value: <code>AWSMarketplace</code> 
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `entityId` field"
  var valid_21626036 = query.getOrDefault("entityId")
  valid_21626036 = validateParameter(valid_21626036, JString, required = true,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "entityId", valid_21626036
  var valid_21626037 = query.getOrDefault("catalog")
  valid_21626037 = validateParameter(valid_21626037, JString, required = true,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "catalog", valid_21626037
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
  var valid_21626038 = header.getOrDefault("X-Amz-Date")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Date", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Security-Token", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Algorithm", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Signature")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Signature", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-Credential")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Credential", valid_21626044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626045: Call_DescribeEntity_21626033; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the metadata and content of the entity.
  ## 
  let valid = call_21626045.validator(path, query, header, formData, body, _)
  let scheme = call_21626045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626045.makeUrl(scheme.get, call_21626045.host, call_21626045.base,
                               call_21626045.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626045, uri, valid, _)

proc call*(call_21626046: Call_DescribeEntity_21626033; entityId: string;
          catalog: string): Recallable =
  ## describeEntity
  ## Returns the metadata and content of the entity.
  ##   entityId: string (required)
  ##           : Required. The unique ID of the entity to describe.
  ##   catalog: string (required)
  ##          : Required. The catalog related to the request. Fixed value: <code>AWSMarketplace</code> 
  var query_21626047 = newJObject()
  add(query_21626047, "entityId", newJString(entityId))
  add(query_21626047, "catalog", newJString(catalog))
  result = call_21626046.call(nil, query_21626047, nil, nil, nil)

var describeEntity* = Call_DescribeEntity_21626033(name: "describeEntity",
    meth: HttpMethod.HttpGet, host: "catalog.marketplace.amazonaws.com",
    route: "/DescribeEntity#catalog&entityId", validator: validate_DescribeEntity_21626034,
    base: "/", makeUrl: url_DescribeEntity_21626035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChangeSets_21626048 = ref object of OpenApiRestCall_21625435
proc url_ListChangeSets_21626050(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListChangeSets_21626049(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns the list of change sets owned by the account being used to make the call. You can filter this list by providing any combination of <code>entityId</code>, <code>ChangeSetName</code>, and status. If you provide more than one filter, the API operation applies a logical AND between the filters.</p> <p>You can describe a change during the 60-day request history retention period for API calls.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626051 = query.getOrDefault("NextToken")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "NextToken", valid_21626051
  var valid_21626052 = query.getOrDefault("MaxResults")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "MaxResults", valid_21626052
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
  var valid_21626053 = header.getOrDefault("X-Amz-Date")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Date", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Security-Token", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Algorithm", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Signature")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Signature", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-Credential")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Credential", valid_21626059
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

proc call*(call_21626061: Call_ListChangeSets_21626048; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the list of change sets owned by the account being used to make the call. You can filter this list by providing any combination of <code>entityId</code>, <code>ChangeSetName</code>, and status. If you provide more than one filter, the API operation applies a logical AND between the filters.</p> <p>You can describe a change during the 60-day request history retention period for API calls.</p>
  ## 
  let valid = call_21626061.validator(path, query, header, formData, body, _)
  let scheme = call_21626061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626061.makeUrl(scheme.get, call_21626061.host, call_21626061.base,
                               call_21626061.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626061, uri, valid, _)

proc call*(call_21626062: Call_ListChangeSets_21626048; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listChangeSets
  ## <p>Returns the list of change sets owned by the account being used to make the call. You can filter this list by providing any combination of <code>entityId</code>, <code>ChangeSetName</code>, and status. If you provide more than one filter, the API operation applies a logical AND between the filters.</p> <p>You can describe a change during the 60-day request history retention period for API calls.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626063 = newJObject()
  var body_21626064 = newJObject()
  add(query_21626063, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626064 = body
  add(query_21626063, "MaxResults", newJString(MaxResults))
  result = call_21626062.call(nil, query_21626063, nil, nil, body_21626064)

var listChangeSets* = Call_ListChangeSets_21626048(name: "listChangeSets",
    meth: HttpMethod.HttpPost, host: "catalog.marketplace.amazonaws.com",
    route: "/ListChangeSets", validator: validate_ListChangeSets_21626049,
    base: "/", makeUrl: url_ListChangeSets_21626050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntities_21626066 = ref object of OpenApiRestCall_21625435
proc url_ListEntities_21626068(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEntities_21626067(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Provides the list of entities of a given type.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626069 = query.getOrDefault("NextToken")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "NextToken", valid_21626069
  var valid_21626070 = query.getOrDefault("MaxResults")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "MaxResults", valid_21626070
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
  var valid_21626071 = header.getOrDefault("X-Amz-Date")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-Date", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Security-Token", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-Algorithm", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-Signature")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Signature", valid_21626075
  var valid_21626076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626076
  var valid_21626077 = header.getOrDefault("X-Amz-Credential")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Credential", valid_21626077
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

proc call*(call_21626079: Call_ListEntities_21626066; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides the list of entities of a given type.
  ## 
  let valid = call_21626079.validator(path, query, header, formData, body, _)
  let scheme = call_21626079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626079.makeUrl(scheme.get, call_21626079.host, call_21626079.base,
                               call_21626079.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626079, uri, valid, _)

proc call*(call_21626080: Call_ListEntities_21626066; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listEntities
  ## Provides the list of entities of a given type.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626081 = newJObject()
  var body_21626082 = newJObject()
  add(query_21626081, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626082 = body
  add(query_21626081, "MaxResults", newJString(MaxResults))
  result = call_21626080.call(nil, query_21626081, nil, nil, body_21626082)

var listEntities* = Call_ListEntities_21626066(name: "listEntities",
    meth: HttpMethod.HttpPost, host: "catalog.marketplace.amazonaws.com",
    route: "/ListEntities", validator: validate_ListEntities_21626067, base: "/",
    makeUrl: url_ListEntities_21626068, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartChangeSet_21626083 = ref object of OpenApiRestCall_21625435
proc url_StartChangeSet_21626085(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartChangeSet_21626084(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation allows you to request changes in your entities.
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
  var valid_21626086 = header.getOrDefault("X-Amz-Date")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Date", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Security-Token", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626088
  var valid_21626089 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-Algorithm", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-Signature")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Signature", valid_21626090
  var valid_21626091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626091
  var valid_21626092 = header.getOrDefault("X-Amz-Credential")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Credential", valid_21626092
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

proc call*(call_21626094: Call_StartChangeSet_21626083; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation allows you to request changes in your entities.
  ## 
  let valid = call_21626094.validator(path, query, header, formData, body, _)
  let scheme = call_21626094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626094.makeUrl(scheme.get, call_21626094.host, call_21626094.base,
                               call_21626094.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626094, uri, valid, _)

proc call*(call_21626095: Call_StartChangeSet_21626083; body: JsonNode): Recallable =
  ## startChangeSet
  ## This operation allows you to request changes in your entities.
  ##   body: JObject (required)
  var body_21626096 = newJObject()
  if body != nil:
    body_21626096 = body
  result = call_21626095.call(nil, nil, nil, nil, body_21626096)

var startChangeSet* = Call_StartChangeSet_21626083(name: "startChangeSet",
    meth: HttpMethod.HttpPost, host: "catalog.marketplace.amazonaws.com",
    route: "/StartChangeSet", validator: validate_StartChangeSet_21626084,
    base: "/", makeUrl: url_StartChangeSet_21626085,
    schemes: {Scheme.Https, Scheme.Http})
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