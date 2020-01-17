
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CancelChangeSet_605927 = ref object of OpenApiRestCall_605589
proc url_CancelChangeSet_605929(protocol: Scheme; host: string; base: string;
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

proc validate_CancelChangeSet_605928(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_606041 = query.getOrDefault("catalog")
  valid_606041 = validateParameter(valid_606041, JString, required = true,
                                 default = nil)
  if valid_606041 != nil:
    section.add "catalog", valid_606041
  var valid_606042 = query.getOrDefault("changeSetId")
  valid_606042 = validateParameter(valid_606042, JString, required = true,
                                 default = nil)
  if valid_606042 != nil:
    section.add "changeSetId", valid_606042
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
  var valid_606043 = header.getOrDefault("X-Amz-Signature")
  valid_606043 = validateParameter(valid_606043, JString, required = false,
                                 default = nil)
  if valid_606043 != nil:
    section.add "X-Amz-Signature", valid_606043
  var valid_606044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606044 = validateParameter(valid_606044, JString, required = false,
                                 default = nil)
  if valid_606044 != nil:
    section.add "X-Amz-Content-Sha256", valid_606044
  var valid_606045 = header.getOrDefault("X-Amz-Date")
  valid_606045 = validateParameter(valid_606045, JString, required = false,
                                 default = nil)
  if valid_606045 != nil:
    section.add "X-Amz-Date", valid_606045
  var valid_606046 = header.getOrDefault("X-Amz-Credential")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "X-Amz-Credential", valid_606046
  var valid_606047 = header.getOrDefault("X-Amz-Security-Token")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-Security-Token", valid_606047
  var valid_606048 = header.getOrDefault("X-Amz-Algorithm")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amz-Algorithm", valid_606048
  var valid_606049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606049 = validateParameter(valid_606049, JString, required = false,
                                 default = nil)
  if valid_606049 != nil:
    section.add "X-Amz-SignedHeaders", valid_606049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606072: Call_CancelChangeSet_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used to cancel an open change request. Must be sent before the status of the request changes to <code>APPLYING</code>, the final stage of completing your change request. You can describe a change during the 60-day request history retention period for API calls.
  ## 
  let valid = call_606072.validator(path, query, header, formData, body)
  let scheme = call_606072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606072.url(scheme.get, call_606072.host, call_606072.base,
                         call_606072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606072, url, valid)

proc call*(call_606143: Call_CancelChangeSet_605927; catalog: string;
          changeSetId: string): Recallable =
  ## cancelChangeSet
  ## Used to cancel an open change request. Must be sent before the status of the request changes to <code>APPLYING</code>, the final stage of completing your change request. You can describe a change during the 60-day request history retention period for API calls.
  ##   catalog: string (required)
  ##          : Required. The catalog related to the request. Fixed value: <code>AWSMarketplace</code>.
  ##   changeSetId: string (required)
  ##              : Required. The unique identifier of the <code>StartChangeSet</code> request that you want to cancel.
  var query_606144 = newJObject()
  add(query_606144, "catalog", newJString(catalog))
  add(query_606144, "changeSetId", newJString(changeSetId))
  result = call_606143.call(nil, query_606144, nil, nil, nil)

var cancelChangeSet* = Call_CancelChangeSet_605927(name: "cancelChangeSet",
    meth: HttpMethod.HttpPatch, host: "catalog.marketplace.amazonaws.com",
    route: "/CancelChangeSet#catalog&changeSetId",
    validator: validate_CancelChangeSet_605928, base: "/", url: url_CancelChangeSet_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChangeSet_606184 = ref object of OpenApiRestCall_605589
proc url_DescribeChangeSet_606186(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeChangeSet_606185(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_606187 = query.getOrDefault("catalog")
  valid_606187 = validateParameter(valid_606187, JString, required = true,
                                 default = nil)
  if valid_606187 != nil:
    section.add "catalog", valid_606187
  var valid_606188 = query.getOrDefault("changeSetId")
  valid_606188 = validateParameter(valid_606188, JString, required = true,
                                 default = nil)
  if valid_606188 != nil:
    section.add "changeSetId", valid_606188
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
  var valid_606189 = header.getOrDefault("X-Amz-Signature")
  valid_606189 = validateParameter(valid_606189, JString, required = false,
                                 default = nil)
  if valid_606189 != nil:
    section.add "X-Amz-Signature", valid_606189
  var valid_606190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606190 = validateParameter(valid_606190, JString, required = false,
                                 default = nil)
  if valid_606190 != nil:
    section.add "X-Amz-Content-Sha256", valid_606190
  var valid_606191 = header.getOrDefault("X-Amz-Date")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "X-Amz-Date", valid_606191
  var valid_606192 = header.getOrDefault("X-Amz-Credential")
  valid_606192 = validateParameter(valid_606192, JString, required = false,
                                 default = nil)
  if valid_606192 != nil:
    section.add "X-Amz-Credential", valid_606192
  var valid_606193 = header.getOrDefault("X-Amz-Security-Token")
  valid_606193 = validateParameter(valid_606193, JString, required = false,
                                 default = nil)
  if valid_606193 != nil:
    section.add "X-Amz-Security-Token", valid_606193
  var valid_606194 = header.getOrDefault("X-Amz-Algorithm")
  valid_606194 = validateParameter(valid_606194, JString, required = false,
                                 default = nil)
  if valid_606194 != nil:
    section.add "X-Amz-Algorithm", valid_606194
  var valid_606195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606195 = validateParameter(valid_606195, JString, required = false,
                                 default = nil)
  if valid_606195 != nil:
    section.add "X-Amz-SignedHeaders", valid_606195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606196: Call_DescribeChangeSet_606184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about a given change set.
  ## 
  let valid = call_606196.validator(path, query, header, formData, body)
  let scheme = call_606196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606196.url(scheme.get, call_606196.host, call_606196.base,
                         call_606196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606196, url, valid)

proc call*(call_606197: Call_DescribeChangeSet_606184; catalog: string;
          changeSetId: string): Recallable =
  ## describeChangeSet
  ## Provides information about a given change set.
  ##   catalog: string (required)
  ##          : Required. The catalog related to the request. Fixed value: <code>AWSMarketplace</code> 
  ##   changeSetId: string (required)
  ##              : Required. The unique identifier for the <code>StartChangeSet</code> request that you want to describe the details for.
  var query_606198 = newJObject()
  add(query_606198, "catalog", newJString(catalog))
  add(query_606198, "changeSetId", newJString(changeSetId))
  result = call_606197.call(nil, query_606198, nil, nil, nil)

var describeChangeSet* = Call_DescribeChangeSet_606184(name: "describeChangeSet",
    meth: HttpMethod.HttpGet, host: "catalog.marketplace.amazonaws.com",
    route: "/DescribeChangeSet#catalog&changeSetId",
    validator: validate_DescribeChangeSet_606185, base: "/",
    url: url_DescribeChangeSet_606186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEntity_606199 = ref object of OpenApiRestCall_605589
proc url_DescribeEntity_606201(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEntity_606200(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_606202 = query.getOrDefault("entityId")
  valid_606202 = validateParameter(valid_606202, JString, required = true,
                                 default = nil)
  if valid_606202 != nil:
    section.add "entityId", valid_606202
  var valid_606203 = query.getOrDefault("catalog")
  valid_606203 = validateParameter(valid_606203, JString, required = true,
                                 default = nil)
  if valid_606203 != nil:
    section.add "catalog", valid_606203
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
  var valid_606204 = header.getOrDefault("X-Amz-Signature")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Signature", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Content-Sha256", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Date")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Date", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Credential")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Credential", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Security-Token")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Security-Token", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-Algorithm")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Algorithm", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-SignedHeaders", valid_606210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606211: Call_DescribeEntity_606199; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the metadata and content of the entity.
  ## 
  let valid = call_606211.validator(path, query, header, formData, body)
  let scheme = call_606211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606211.url(scheme.get, call_606211.host, call_606211.base,
                         call_606211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606211, url, valid)

proc call*(call_606212: Call_DescribeEntity_606199; entityId: string; catalog: string): Recallable =
  ## describeEntity
  ## Returns the metadata and content of the entity.
  ##   entityId: string (required)
  ##           : Required. The unique ID of the entity to describe.
  ##   catalog: string (required)
  ##          : Required. The catalog related to the request. Fixed value: <code>AWSMarketplace</code> 
  var query_606213 = newJObject()
  add(query_606213, "entityId", newJString(entityId))
  add(query_606213, "catalog", newJString(catalog))
  result = call_606212.call(nil, query_606213, nil, nil, nil)

var describeEntity* = Call_DescribeEntity_606199(name: "describeEntity",
    meth: HttpMethod.HttpGet, host: "catalog.marketplace.amazonaws.com",
    route: "/DescribeEntity#catalog&entityId", validator: validate_DescribeEntity_606200,
    base: "/", url: url_DescribeEntity_606201, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChangeSets_606214 = ref object of OpenApiRestCall_605589
proc url_ListChangeSets_606216(protocol: Scheme; host: string; base: string;
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

proc validate_ListChangeSets_606215(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_606217 = query.getOrDefault("MaxResults")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "MaxResults", valid_606217
  var valid_606218 = query.getOrDefault("NextToken")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "NextToken", valid_606218
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
  var valid_606219 = header.getOrDefault("X-Amz-Signature")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Signature", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Content-Sha256", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-Date")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Date", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-Credential")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Credential", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Security-Token")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Security-Token", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Algorithm")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Algorithm", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-SignedHeaders", valid_606225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606227: Call_ListChangeSets_606214; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the list of change sets owned by the account being used to make the call. You can filter this list by providing any combination of <code>entityId</code>, <code>ChangeSetName</code>, and status. If you provide more than one filter, the API operation applies a logical AND between the filters.</p> <p>You can describe a change during the 60-day request history retention period for API calls.</p>
  ## 
  let valid = call_606227.validator(path, query, header, formData, body)
  let scheme = call_606227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606227.url(scheme.get, call_606227.host, call_606227.base,
                         call_606227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606227, url, valid)

proc call*(call_606228: Call_ListChangeSets_606214; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listChangeSets
  ## <p>Returns the list of change sets owned by the account being used to make the call. You can filter this list by providing any combination of <code>entityId</code>, <code>ChangeSetName</code>, and status. If you provide more than one filter, the API operation applies a logical AND between the filters.</p> <p>You can describe a change during the 60-day request history retention period for API calls.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606229 = newJObject()
  var body_606230 = newJObject()
  add(query_606229, "MaxResults", newJString(MaxResults))
  add(query_606229, "NextToken", newJString(NextToken))
  if body != nil:
    body_606230 = body
  result = call_606228.call(nil, query_606229, nil, nil, body_606230)

var listChangeSets* = Call_ListChangeSets_606214(name: "listChangeSets",
    meth: HttpMethod.HttpPost, host: "catalog.marketplace.amazonaws.com",
    route: "/ListChangeSets", validator: validate_ListChangeSets_606215, base: "/",
    url: url_ListChangeSets_606216, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntities_606231 = ref object of OpenApiRestCall_605589
proc url_ListEntities_606233(protocol: Scheme; host: string; base: string;
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

proc validate_ListEntities_606232(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606234 = query.getOrDefault("MaxResults")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "MaxResults", valid_606234
  var valid_606235 = query.getOrDefault("NextToken")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "NextToken", valid_606235
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
  var valid_606236 = header.getOrDefault("X-Amz-Signature")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Signature", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Content-Sha256", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-Date")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Date", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Credential")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Credential", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Security-Token")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Security-Token", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Algorithm")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Algorithm", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-SignedHeaders", valid_606242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606244: Call_ListEntities_606231; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the list of entities of a given type.
  ## 
  let valid = call_606244.validator(path, query, header, formData, body)
  let scheme = call_606244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606244.url(scheme.get, call_606244.host, call_606244.base,
                         call_606244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606244, url, valid)

proc call*(call_606245: Call_ListEntities_606231; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEntities
  ## Provides the list of entities of a given type.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606246 = newJObject()
  var body_606247 = newJObject()
  add(query_606246, "MaxResults", newJString(MaxResults))
  add(query_606246, "NextToken", newJString(NextToken))
  if body != nil:
    body_606247 = body
  result = call_606245.call(nil, query_606246, nil, nil, body_606247)

var listEntities* = Call_ListEntities_606231(name: "listEntities",
    meth: HttpMethod.HttpPost, host: "catalog.marketplace.amazonaws.com",
    route: "/ListEntities", validator: validate_ListEntities_606232, base: "/",
    url: url_ListEntities_606233, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartChangeSet_606248 = ref object of OpenApiRestCall_605589
proc url_StartChangeSet_606250(protocol: Scheme; host: string; base: string;
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

proc validate_StartChangeSet_606249(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## This operation allows you to request changes in your entities.
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
  var valid_606251 = header.getOrDefault("X-Amz-Signature")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Signature", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Content-Sha256", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-Date")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-Date", valid_606253
  var valid_606254 = header.getOrDefault("X-Amz-Credential")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-Credential", valid_606254
  var valid_606255 = header.getOrDefault("X-Amz-Security-Token")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Security-Token", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-Algorithm")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-Algorithm", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-SignedHeaders", valid_606257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606259: Call_StartChangeSet_606248; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation allows you to request changes in your entities.
  ## 
  let valid = call_606259.validator(path, query, header, formData, body)
  let scheme = call_606259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606259.url(scheme.get, call_606259.host, call_606259.base,
                         call_606259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606259, url, valid)

proc call*(call_606260: Call_StartChangeSet_606248; body: JsonNode): Recallable =
  ## startChangeSet
  ## This operation allows you to request changes in your entities.
  ##   body: JObject (required)
  var body_606261 = newJObject()
  if body != nil:
    body_606261 = body
  result = call_606260.call(nil, nil, nil, nil, body_606261)

var startChangeSet* = Call_StartChangeSet_606248(name: "startChangeSet",
    meth: HttpMethod.HttpPost, host: "catalog.marketplace.amazonaws.com",
    route: "/StartChangeSet", validator: validate_StartChangeSet_606249, base: "/",
    url: url_StartChangeSet_606250, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
