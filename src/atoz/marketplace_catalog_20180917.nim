
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
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

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "catalog.marketplace.ap-northeast-1.amazonaws.com", "ap-southeast-1": "catalog.marketplace.ap-southeast-1.amazonaws.com", "us-west-2": "catalog.marketplace.us-west-2.amazonaws.com", "eu-west-2": "catalog.marketplace.eu-west-2.amazonaws.com", "ap-northeast-3": "catalog.marketplace.ap-northeast-3.amazonaws.com", "eu-central-1": "catalog.marketplace.eu-central-1.amazonaws.com", "us-east-2": "catalog.marketplace.us-east-2.amazonaws.com", "us-east-1": "catalog.marketplace.us-east-1.amazonaws.com", "cn-northwest-1": "catalog.marketplace.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "catalog.marketplace.ap-south-1.amazonaws.com", "eu-north-1": "catalog.marketplace.eu-north-1.amazonaws.com", "ap-northeast-2": "catalog.marketplace.ap-northeast-2.amazonaws.com", "us-west-1": "catalog.marketplace.us-west-1.amazonaws.com", "us-gov-east-1": "catalog.marketplace.us-gov-east-1.amazonaws.com", "eu-west-3": "catalog.marketplace.eu-west-3.amazonaws.com", "cn-north-1": "catalog.marketplace.cn-north-1.amazonaws.com.cn", "sa-east-1": "catalog.marketplace.sa-east-1.amazonaws.com", "eu-west-1": "catalog.marketplace.eu-west-1.amazonaws.com", "us-gov-west-1": "catalog.marketplace.us-gov-west-1.amazonaws.com", "ap-southeast-2": "catalog.marketplace.ap-southeast-2.amazonaws.com", "ca-central-1": "catalog.marketplace.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CancelChangeSet_402656288 = ref object of OpenApiRestCall_402656038
proc url_CancelChangeSet_402656290(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelChangeSet_402656289(path: JsonNode; query: JsonNode;
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
  ##   
                                                                                                                                       ## changeSetId: JString (required)
                                                                                                                                       ##              
                                                                                                                                       ## : 
                                                                                                                                       ## Required. 
                                                                                                                                       ## The 
                                                                                                                                       ## unique 
                                                                                                                                       ## identifier 
                                                                                                                                       ## of 
                                                                                                                                       ## the 
                                                                                                                                       ## <code>StartChangeSet</code> 
                                                                                                                                       ## request 
                                                                                                                                       ## that 
                                                                                                                                       ## you 
                                                                                                                                       ## want 
                                                                                                                                       ## to 
                                                                                                                                       ## cancel.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `catalog` field"
  var valid_402656369 = query.getOrDefault("catalog")
  valid_402656369 = validateParameter(valid_402656369, JString, required = true,
                                      default = nil)
  if valid_402656369 != nil:
    section.add "catalog", valid_402656369
  var valid_402656370 = query.getOrDefault("changeSetId")
  valid_402656370 = validateParameter(valid_402656370, JString, required = true,
                                      default = nil)
  if valid_402656370 != nil:
    section.add "changeSetId", valid_402656370
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656371 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656371 = validateParameter(valid_402656371, JString,
                                      required = false, default = nil)
  if valid_402656371 != nil:
    section.add "X-Amz-Security-Token", valid_402656371
  var valid_402656372 = header.getOrDefault("X-Amz-Signature")
  valid_402656372 = validateParameter(valid_402656372, JString,
                                      required = false, default = nil)
  if valid_402656372 != nil:
    section.add "X-Amz-Signature", valid_402656372
  var valid_402656373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656373 = validateParameter(valid_402656373, JString,
                                      required = false, default = nil)
  if valid_402656373 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656373
  var valid_402656374 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656374 = validateParameter(valid_402656374, JString,
                                      required = false, default = nil)
  if valid_402656374 != nil:
    section.add "X-Amz-Algorithm", valid_402656374
  var valid_402656375 = header.getOrDefault("X-Amz-Date")
  valid_402656375 = validateParameter(valid_402656375, JString,
                                      required = false, default = nil)
  if valid_402656375 != nil:
    section.add "X-Amz-Date", valid_402656375
  var valid_402656376 = header.getOrDefault("X-Amz-Credential")
  valid_402656376 = validateParameter(valid_402656376, JString,
                                      required = false, default = nil)
  if valid_402656376 != nil:
    section.add "X-Amz-Credential", valid_402656376
  var valid_402656377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656377 = validateParameter(valid_402656377, JString,
                                      required = false, default = nil)
  if valid_402656377 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656391: Call_CancelChangeSet_402656288; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Used to cancel an open change request. Must be sent before the status of the request changes to <code>APPLYING</code>, the final stage of completing your change request. You can describe a change during the 60-day request history retention period for API calls.
                                                                                         ## 
  let valid = call_402656391.validator(path, query, header, formData, body, _)
  let scheme = call_402656391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656391.makeUrl(scheme.get, call_402656391.host, call_402656391.base,
                                   call_402656391.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656391, uri, valid, _)

proc call*(call_402656440: Call_CancelChangeSet_402656288; catalog: string;
           changeSetId: string): Recallable =
  ## cancelChangeSet
  ## Used to cancel an open change request. Must be sent before the status of the request changes to <code>APPLYING</code>, the final stage of completing your change request. You can describe a change during the 60-day request history retention period for API calls.
  ##   
                                                                                                                                                                                                                                                                          ## catalog: string (required)
                                                                                                                                                                                                                                                                          ##          
                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                          ## Required. 
                                                                                                                                                                                                                                                                          ## The 
                                                                                                                                                                                                                                                                          ## catalog 
                                                                                                                                                                                                                                                                          ## related 
                                                                                                                                                                                                                                                                          ## to 
                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                          ## request. 
                                                                                                                                                                                                                                                                          ## Fixed 
                                                                                                                                                                                                                                                                          ## value: 
                                                                                                                                                                                                                                                                          ## <code>AWSMarketplace</code>.
  ##   
                                                                                                                                                                                                                                                                                                         ## changeSetId: string (required)
                                                                                                                                                                                                                                                                                                         ##              
                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                         ## Required. 
                                                                                                                                                                                                                                                                                                         ## The 
                                                                                                                                                                                                                                                                                                         ## unique 
                                                                                                                                                                                                                                                                                                         ## identifier 
                                                                                                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                         ## <code>StartChangeSet</code> 
                                                                                                                                                                                                                                                                                                         ## request 
                                                                                                                                                                                                                                                                                                         ## that 
                                                                                                                                                                                                                                                                                                         ## you 
                                                                                                                                                                                                                                                                                                         ## want 
                                                                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                                                                         ## cancel.
  var query_402656441 = newJObject()
  add(query_402656441, "catalog", newJString(catalog))
  add(query_402656441, "changeSetId", newJString(changeSetId))
  result = call_402656440.call(nil, query_402656441, nil, nil, nil)

var cancelChangeSet* = Call_CancelChangeSet_402656288(name: "cancelChangeSet",
    meth: HttpMethod.HttpPatch, host: "catalog.marketplace.amazonaws.com",
    route: "/CancelChangeSet#catalog&changeSetId",
    validator: validate_CancelChangeSet_402656289, base: "/",
    makeUrl: url_CancelChangeSet_402656290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChangeSet_402656471 = ref object of OpenApiRestCall_402656038
proc url_DescribeChangeSet_402656473(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeChangeSet_402656472(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   
                                                                                                                                       ## changeSetId: JString (required)
                                                                                                                                       ##              
                                                                                                                                       ## : 
                                                                                                                                       ## Required. 
                                                                                                                                       ## The 
                                                                                                                                       ## unique 
                                                                                                                                       ## identifier 
                                                                                                                                       ## for 
                                                                                                                                       ## the 
                                                                                                                                       ## <code>StartChangeSet</code> 
                                                                                                                                       ## request 
                                                                                                                                       ## that 
                                                                                                                                       ## you 
                                                                                                                                       ## want 
                                                                                                                                       ## to 
                                                                                                                                       ## describe 
                                                                                                                                       ## the 
                                                                                                                                       ## details 
                                                                                                                                       ## for.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `catalog` field"
  var valid_402656474 = query.getOrDefault("catalog")
  valid_402656474 = validateParameter(valid_402656474, JString, required = true,
                                      default = nil)
  if valid_402656474 != nil:
    section.add "catalog", valid_402656474
  var valid_402656475 = query.getOrDefault("changeSetId")
  valid_402656475 = validateParameter(valid_402656475, JString, required = true,
                                      default = nil)
  if valid_402656475 != nil:
    section.add "changeSetId", valid_402656475
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656476 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656476 = validateParameter(valid_402656476, JString,
                                      required = false, default = nil)
  if valid_402656476 != nil:
    section.add "X-Amz-Security-Token", valid_402656476
  var valid_402656477 = header.getOrDefault("X-Amz-Signature")
  valid_402656477 = validateParameter(valid_402656477, JString,
                                      required = false, default = nil)
  if valid_402656477 != nil:
    section.add "X-Amz-Signature", valid_402656477
  var valid_402656478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656478 = validateParameter(valid_402656478, JString,
                                      required = false, default = nil)
  if valid_402656478 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656478
  var valid_402656479 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656479 = validateParameter(valid_402656479, JString,
                                      required = false, default = nil)
  if valid_402656479 != nil:
    section.add "X-Amz-Algorithm", valid_402656479
  var valid_402656480 = header.getOrDefault("X-Amz-Date")
  valid_402656480 = validateParameter(valid_402656480, JString,
                                      required = false, default = nil)
  if valid_402656480 != nil:
    section.add "X-Amz-Date", valid_402656480
  var valid_402656481 = header.getOrDefault("X-Amz-Credential")
  valid_402656481 = validateParameter(valid_402656481, JString,
                                      required = false, default = nil)
  if valid_402656481 != nil:
    section.add "X-Amz-Credential", valid_402656481
  var valid_402656482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656483: Call_DescribeChangeSet_402656471;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides information about a given change set.
                                                                                         ## 
  let valid = call_402656483.validator(path, query, header, formData, body, _)
  let scheme = call_402656483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656483.makeUrl(scheme.get, call_402656483.host, call_402656483.base,
                                   call_402656483.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656483, uri, valid, _)

proc call*(call_402656484: Call_DescribeChangeSet_402656471; catalog: string;
           changeSetId: string): Recallable =
  ## describeChangeSet
  ## Provides information about a given change set.
  ##   catalog: string (required)
                                                   ##          : Required. The catalog related to the request. Fixed value: <code>AWSMarketplace</code> 
  ##   
                                                                                                                                                        ## changeSetId: string (required)
                                                                                                                                                        ##              
                                                                                                                                                        ## : 
                                                                                                                                                        ## Required. 
                                                                                                                                                        ## The 
                                                                                                                                                        ## unique 
                                                                                                                                                        ## identifier 
                                                                                                                                                        ## for 
                                                                                                                                                        ## the 
                                                                                                                                                        ## <code>StartChangeSet</code> 
                                                                                                                                                        ## request 
                                                                                                                                                        ## that 
                                                                                                                                                        ## you 
                                                                                                                                                        ## want 
                                                                                                                                                        ## to 
                                                                                                                                                        ## describe 
                                                                                                                                                        ## the 
                                                                                                                                                        ## details 
                                                                                                                                                        ## for.
  var query_402656485 = newJObject()
  add(query_402656485, "catalog", newJString(catalog))
  add(query_402656485, "changeSetId", newJString(changeSetId))
  result = call_402656484.call(nil, query_402656485, nil, nil, nil)

var describeChangeSet* = Call_DescribeChangeSet_402656471(
    name: "describeChangeSet", meth: HttpMethod.HttpGet,
    host: "catalog.marketplace.amazonaws.com",
    route: "/DescribeChangeSet#catalog&changeSetId",
    validator: validate_DescribeChangeSet_402656472, base: "/",
    makeUrl: url_DescribeChangeSet_402656473,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEntity_402656486 = ref object of OpenApiRestCall_402656038
proc url_DescribeEntity_402656488(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEntity_402656487(path: JsonNode; query: JsonNode;
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
  ##   
                                                                                                   ## catalog: JString (required)
                                                                                                   ##          
                                                                                                   ## : 
                                                                                                   ## Required. 
                                                                                                   ## The 
                                                                                                   ## catalog 
                                                                                                   ## related 
                                                                                                   ## to 
                                                                                                   ## the 
                                                                                                   ## request. 
                                                                                                   ## Fixed 
                                                                                                   ## value: 
                                                                                                   ## <code>AWSMarketplace</code> 
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `entityId` field"
  var valid_402656489 = query.getOrDefault("entityId")
  valid_402656489 = validateParameter(valid_402656489, JString, required = true,
                                      default = nil)
  if valid_402656489 != nil:
    section.add "entityId", valid_402656489
  var valid_402656490 = query.getOrDefault("catalog")
  valid_402656490 = validateParameter(valid_402656490, JString, required = true,
                                      default = nil)
  if valid_402656490 != nil:
    section.add "catalog", valid_402656490
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656491 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Security-Token", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Signature")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Signature", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Algorithm", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Date")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Date", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Credential")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Credential", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656498: Call_DescribeEntity_402656486; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the metadata and content of the entity.
                                                                                         ## 
  let valid = call_402656498.validator(path, query, header, formData, body, _)
  let scheme = call_402656498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656498.makeUrl(scheme.get, call_402656498.host, call_402656498.base,
                                   call_402656498.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656498, uri, valid, _)

proc call*(call_402656499: Call_DescribeEntity_402656486; entityId: string;
           catalog: string): Recallable =
  ## describeEntity
  ## Returns the metadata and content of the entity.
  ##   entityId: string (required)
                                                    ##           : Required. The unique ID of the entity to describe.
  ##   
                                                                                                                     ## catalog: string (required)
                                                                                                                     ##          
                                                                                                                     ## : 
                                                                                                                     ## Required. 
                                                                                                                     ## The 
                                                                                                                     ## catalog 
                                                                                                                     ## related 
                                                                                                                     ## to 
                                                                                                                     ## the 
                                                                                                                     ## request. 
                                                                                                                     ## Fixed 
                                                                                                                     ## value: 
                                                                                                                     ## <code>AWSMarketplace</code> 
  var query_402656500 = newJObject()
  add(query_402656500, "entityId", newJString(entityId))
  add(query_402656500, "catalog", newJString(catalog))
  result = call_402656499.call(nil, query_402656500, nil, nil, nil)

var describeEntity* = Call_DescribeEntity_402656486(name: "describeEntity",
    meth: HttpMethod.HttpGet, host: "catalog.marketplace.amazonaws.com",
    route: "/DescribeEntity#catalog&entityId",
    validator: validate_DescribeEntity_402656487, base: "/",
    makeUrl: url_DescribeEntity_402656488, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChangeSets_402656501 = ref object of OpenApiRestCall_402656038
proc url_ListChangeSets_402656503(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListChangeSets_402656502(path: JsonNode; query: JsonNode;
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
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656504 = query.getOrDefault("MaxResults")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "MaxResults", valid_402656504
  var valid_402656505 = query.getOrDefault("NextToken")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "NextToken", valid_402656505
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656506 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Security-Token", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Signature")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Signature", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Algorithm", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Date")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Date", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Credential")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Credential", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656512
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

proc call*(call_402656514: Call_ListChangeSets_402656501; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the list of change sets owned by the account being used to make the call. You can filter this list by providing any combination of <code>entityId</code>, <code>ChangeSetName</code>, and status. If you provide more than one filter, the API operation applies a logical AND between the filters.</p> <p>You can describe a change during the 60-day request history retention period for API calls.</p>
                                                                                         ## 
  let valid = call_402656514.validator(path, query, header, formData, body, _)
  let scheme = call_402656514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656514.makeUrl(scheme.get, call_402656514.host, call_402656514.base,
                                   call_402656514.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656514, uri, valid, _)

proc call*(call_402656515: Call_ListChangeSets_402656501; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listChangeSets
  ## <p>Returns the list of change sets owned by the account being used to make the call. You can filter this list by providing any combination of <code>entityId</code>, <code>ChangeSetName</code>, and status. If you provide more than one filter, the API operation applies a logical AND between the filters.</p> <p>You can describe a change during the 60-day request history retention period for API calls.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                          ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                          ##             
                                                                                                                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                          ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## token
  var query_402656516 = newJObject()
  var body_402656517 = newJObject()
  add(query_402656516, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656517 = body
  add(query_402656516, "NextToken", newJString(NextToken))
  result = call_402656515.call(nil, query_402656516, nil, nil, body_402656517)

var listChangeSets* = Call_ListChangeSets_402656501(name: "listChangeSets",
    meth: HttpMethod.HttpPost, host: "catalog.marketplace.amazonaws.com",
    route: "/ListChangeSets", validator: validate_ListChangeSets_402656502,
    base: "/", makeUrl: url_ListChangeSets_402656503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntities_402656518 = ref object of OpenApiRestCall_402656038
proc url_ListEntities_402656520(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEntities_402656519(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides the list of entities of a given type.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656521 = query.getOrDefault("MaxResults")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "MaxResults", valid_402656521
  var valid_402656522 = query.getOrDefault("NextToken")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "NextToken", valid_402656522
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Security-Token", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Signature")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Signature", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Algorithm", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Date")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Date", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Credential")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Credential", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
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

proc call*(call_402656531: Call_ListEntities_402656518; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides the list of entities of a given type.
                                                                                         ## 
  let valid = call_402656531.validator(path, query, header, formData, body, _)
  let scheme = call_402656531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656531.makeUrl(scheme.get, call_402656531.host, call_402656531.base,
                                   call_402656531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656531, uri, valid, _)

proc call*(call_402656532: Call_ListEntities_402656518; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEntities
  ## Provides the list of entities of a given type.
  ##   MaxResults: string
                                                   ##             : Pagination limit
  ##   
                                                                                    ## body: JObject (required)
  ##   
                                                                                                               ## NextToken: string
                                                                                                               ##            
                                                                                                               ## : 
                                                                                                               ## Pagination 
                                                                                                               ## token
  var query_402656533 = newJObject()
  var body_402656534 = newJObject()
  add(query_402656533, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656534 = body
  add(query_402656533, "NextToken", newJString(NextToken))
  result = call_402656532.call(nil, query_402656533, nil, nil, body_402656534)

var listEntities* = Call_ListEntities_402656518(name: "listEntities",
    meth: HttpMethod.HttpPost, host: "catalog.marketplace.amazonaws.com",
    route: "/ListEntities", validator: validate_ListEntities_402656519,
    base: "/", makeUrl: url_ListEntities_402656520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartChangeSet_402656535 = ref object of OpenApiRestCall_402656038
proc url_StartChangeSet_402656537(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartChangeSet_402656536(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656538 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Security-Token", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Signature")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Signature", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Algorithm", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Date")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Date", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Credential")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Credential", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656544
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

proc call*(call_402656546: Call_StartChangeSet_402656535; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation allows you to request changes in your entities.
                                                                                         ## 
  let valid = call_402656546.validator(path, query, header, formData, body, _)
  let scheme = call_402656546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656546.makeUrl(scheme.get, call_402656546.host, call_402656546.base,
                                   call_402656546.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656546, uri, valid, _)

proc call*(call_402656547: Call_StartChangeSet_402656535; body: JsonNode): Recallable =
  ## startChangeSet
  ## This operation allows you to request changes in your entities.
  ##   body: JObject (required)
  var body_402656548 = newJObject()
  if body != nil:
    body_402656548 = body
  result = call_402656547.call(nil, nil, nil, nil, body_402656548)

var startChangeSet* = Call_StartChangeSet_402656535(name: "startChangeSet",
    meth: HttpMethod.HttpPost, host: "catalog.marketplace.amazonaws.com",
    route: "/StartChangeSet", validator: validate_StartChangeSet_402656536,
    base: "/", makeUrl: url_StartChangeSet_402656537,
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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