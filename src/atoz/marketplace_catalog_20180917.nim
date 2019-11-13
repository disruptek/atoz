
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

  OpenApiRestCall_593389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593389): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CancelChangeSet_593727 = ref object of OpenApiRestCall_593389
proc url_CancelChangeSet_593729(protocol: Scheme; host: string; base: string;
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

proc validate_CancelChangeSet_593728(path: JsonNode; query: JsonNode;
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
  var valid_593841 = query.getOrDefault("catalog")
  valid_593841 = validateParameter(valid_593841, JString, required = true,
                                 default = nil)
  if valid_593841 != nil:
    section.add "catalog", valid_593841
  var valid_593842 = query.getOrDefault("changeSetId")
  valid_593842 = validateParameter(valid_593842, JString, required = true,
                                 default = nil)
  if valid_593842 != nil:
    section.add "changeSetId", valid_593842
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
  var valid_593843 = header.getOrDefault("X-Amz-Signature")
  valid_593843 = validateParameter(valid_593843, JString, required = false,
                                 default = nil)
  if valid_593843 != nil:
    section.add "X-Amz-Signature", valid_593843
  var valid_593844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593844 = validateParameter(valid_593844, JString, required = false,
                                 default = nil)
  if valid_593844 != nil:
    section.add "X-Amz-Content-Sha256", valid_593844
  var valid_593845 = header.getOrDefault("X-Amz-Date")
  valid_593845 = validateParameter(valid_593845, JString, required = false,
                                 default = nil)
  if valid_593845 != nil:
    section.add "X-Amz-Date", valid_593845
  var valid_593846 = header.getOrDefault("X-Amz-Credential")
  valid_593846 = validateParameter(valid_593846, JString, required = false,
                                 default = nil)
  if valid_593846 != nil:
    section.add "X-Amz-Credential", valid_593846
  var valid_593847 = header.getOrDefault("X-Amz-Security-Token")
  valid_593847 = validateParameter(valid_593847, JString, required = false,
                                 default = nil)
  if valid_593847 != nil:
    section.add "X-Amz-Security-Token", valid_593847
  var valid_593848 = header.getOrDefault("X-Amz-Algorithm")
  valid_593848 = validateParameter(valid_593848, JString, required = false,
                                 default = nil)
  if valid_593848 != nil:
    section.add "X-Amz-Algorithm", valid_593848
  var valid_593849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593849 = validateParameter(valid_593849, JString, required = false,
                                 default = nil)
  if valid_593849 != nil:
    section.add "X-Amz-SignedHeaders", valid_593849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593872: Call_CancelChangeSet_593727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used to cancel an open change request. Must be sent before the status of the request changes to <code>APPLYING</code>, the final stage of completing your change request. You can describe a change during the 60-day request history retention period for API calls.
  ## 
  let valid = call_593872.validator(path, query, header, formData, body)
  let scheme = call_593872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593872.url(scheme.get, call_593872.host, call_593872.base,
                         call_593872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593872, url, valid)

proc call*(call_593943: Call_CancelChangeSet_593727; catalog: string;
          changeSetId: string): Recallable =
  ## cancelChangeSet
  ## Used to cancel an open change request. Must be sent before the status of the request changes to <code>APPLYING</code>, the final stage of completing your change request. You can describe a change during the 60-day request history retention period for API calls.
  ##   catalog: string (required)
  ##          : Required. The catalog related to the request. Fixed value: <code>AWSMarketplace</code>.
  ##   changeSetId: string (required)
  ##              : Required. The unique identifier of the <code>StartChangeSet</code> request that you want to cancel.
  var query_593944 = newJObject()
  add(query_593944, "catalog", newJString(catalog))
  add(query_593944, "changeSetId", newJString(changeSetId))
  result = call_593943.call(nil, query_593944, nil, nil, nil)

var cancelChangeSet* = Call_CancelChangeSet_593727(name: "cancelChangeSet",
    meth: HttpMethod.HttpPatch, host: "catalog.marketplace.amazonaws.com",
    route: "/CancelChangeSet#catalog&changeSetId",
    validator: validate_CancelChangeSet_593728, base: "/", url: url_CancelChangeSet_593729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChangeSet_593984 = ref object of OpenApiRestCall_593389
proc url_DescribeChangeSet_593986(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeChangeSet_593985(path: JsonNode; query: JsonNode;
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
  var valid_593987 = query.getOrDefault("catalog")
  valid_593987 = validateParameter(valid_593987, JString, required = true,
                                 default = nil)
  if valid_593987 != nil:
    section.add "catalog", valid_593987
  var valid_593988 = query.getOrDefault("changeSetId")
  valid_593988 = validateParameter(valid_593988, JString, required = true,
                                 default = nil)
  if valid_593988 != nil:
    section.add "changeSetId", valid_593988
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
  var valid_593989 = header.getOrDefault("X-Amz-Signature")
  valid_593989 = validateParameter(valid_593989, JString, required = false,
                                 default = nil)
  if valid_593989 != nil:
    section.add "X-Amz-Signature", valid_593989
  var valid_593990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593990 = validateParameter(valid_593990, JString, required = false,
                                 default = nil)
  if valid_593990 != nil:
    section.add "X-Amz-Content-Sha256", valid_593990
  var valid_593991 = header.getOrDefault("X-Amz-Date")
  valid_593991 = validateParameter(valid_593991, JString, required = false,
                                 default = nil)
  if valid_593991 != nil:
    section.add "X-Amz-Date", valid_593991
  var valid_593992 = header.getOrDefault("X-Amz-Credential")
  valid_593992 = validateParameter(valid_593992, JString, required = false,
                                 default = nil)
  if valid_593992 != nil:
    section.add "X-Amz-Credential", valid_593992
  var valid_593993 = header.getOrDefault("X-Amz-Security-Token")
  valid_593993 = validateParameter(valid_593993, JString, required = false,
                                 default = nil)
  if valid_593993 != nil:
    section.add "X-Amz-Security-Token", valid_593993
  var valid_593994 = header.getOrDefault("X-Amz-Algorithm")
  valid_593994 = validateParameter(valid_593994, JString, required = false,
                                 default = nil)
  if valid_593994 != nil:
    section.add "X-Amz-Algorithm", valid_593994
  var valid_593995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593995 = validateParameter(valid_593995, JString, required = false,
                                 default = nil)
  if valid_593995 != nil:
    section.add "X-Amz-SignedHeaders", valid_593995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593996: Call_DescribeChangeSet_593984; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about a given change set.
  ## 
  let valid = call_593996.validator(path, query, header, formData, body)
  let scheme = call_593996.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593996.url(scheme.get, call_593996.host, call_593996.base,
                         call_593996.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593996, url, valid)

proc call*(call_593997: Call_DescribeChangeSet_593984; catalog: string;
          changeSetId: string): Recallable =
  ## describeChangeSet
  ## Provides information about a given change set.
  ##   catalog: string (required)
  ##          : Required. The catalog related to the request. Fixed value: <code>AWSMarketplace</code> 
  ##   changeSetId: string (required)
  ##              : Required. The unique identifier for the <code>StartChangeSet</code> request that you want to describe the details for.
  var query_593998 = newJObject()
  add(query_593998, "catalog", newJString(catalog))
  add(query_593998, "changeSetId", newJString(changeSetId))
  result = call_593997.call(nil, query_593998, nil, nil, nil)

var describeChangeSet* = Call_DescribeChangeSet_593984(name: "describeChangeSet",
    meth: HttpMethod.HttpGet, host: "catalog.marketplace.amazonaws.com",
    route: "/DescribeChangeSet#catalog&changeSetId",
    validator: validate_DescribeChangeSet_593985, base: "/",
    url: url_DescribeChangeSet_593986, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEntity_593999 = ref object of OpenApiRestCall_593389
proc url_DescribeEntity_594001(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEntity_594000(path: JsonNode; query: JsonNode;
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
  var valid_594002 = query.getOrDefault("entityId")
  valid_594002 = validateParameter(valid_594002, JString, required = true,
                                 default = nil)
  if valid_594002 != nil:
    section.add "entityId", valid_594002
  var valid_594003 = query.getOrDefault("catalog")
  valid_594003 = validateParameter(valid_594003, JString, required = true,
                                 default = nil)
  if valid_594003 != nil:
    section.add "catalog", valid_594003
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
  var valid_594004 = header.getOrDefault("X-Amz-Signature")
  valid_594004 = validateParameter(valid_594004, JString, required = false,
                                 default = nil)
  if valid_594004 != nil:
    section.add "X-Amz-Signature", valid_594004
  var valid_594005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594005 = validateParameter(valid_594005, JString, required = false,
                                 default = nil)
  if valid_594005 != nil:
    section.add "X-Amz-Content-Sha256", valid_594005
  var valid_594006 = header.getOrDefault("X-Amz-Date")
  valid_594006 = validateParameter(valid_594006, JString, required = false,
                                 default = nil)
  if valid_594006 != nil:
    section.add "X-Amz-Date", valid_594006
  var valid_594007 = header.getOrDefault("X-Amz-Credential")
  valid_594007 = validateParameter(valid_594007, JString, required = false,
                                 default = nil)
  if valid_594007 != nil:
    section.add "X-Amz-Credential", valid_594007
  var valid_594008 = header.getOrDefault("X-Amz-Security-Token")
  valid_594008 = validateParameter(valid_594008, JString, required = false,
                                 default = nil)
  if valid_594008 != nil:
    section.add "X-Amz-Security-Token", valid_594008
  var valid_594009 = header.getOrDefault("X-Amz-Algorithm")
  valid_594009 = validateParameter(valid_594009, JString, required = false,
                                 default = nil)
  if valid_594009 != nil:
    section.add "X-Amz-Algorithm", valid_594009
  var valid_594010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594010 = validateParameter(valid_594010, JString, required = false,
                                 default = nil)
  if valid_594010 != nil:
    section.add "X-Amz-SignedHeaders", valid_594010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594011: Call_DescribeEntity_593999; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the metadata and content of the entity.
  ## 
  let valid = call_594011.validator(path, query, header, formData, body)
  let scheme = call_594011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594011.url(scheme.get, call_594011.host, call_594011.base,
                         call_594011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594011, url, valid)

proc call*(call_594012: Call_DescribeEntity_593999; entityId: string; catalog: string): Recallable =
  ## describeEntity
  ## Returns the metadata and content of the entity.
  ##   entityId: string (required)
  ##           : Required. The unique ID of the entity to describe.
  ##   catalog: string (required)
  ##          : Required. The catalog related to the request. Fixed value: <code>AWSMarketplace</code> 
  var query_594013 = newJObject()
  add(query_594013, "entityId", newJString(entityId))
  add(query_594013, "catalog", newJString(catalog))
  result = call_594012.call(nil, query_594013, nil, nil, nil)

var describeEntity* = Call_DescribeEntity_593999(name: "describeEntity",
    meth: HttpMethod.HttpGet, host: "catalog.marketplace.amazonaws.com",
    route: "/DescribeEntity#catalog&entityId", validator: validate_DescribeEntity_594000,
    base: "/", url: url_DescribeEntity_594001, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChangeSets_594014 = ref object of OpenApiRestCall_593389
proc url_ListChangeSets_594016(protocol: Scheme; host: string; base: string;
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

proc validate_ListChangeSets_594015(path: JsonNode; query: JsonNode;
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
  var valid_594017 = query.getOrDefault("MaxResults")
  valid_594017 = validateParameter(valid_594017, JString, required = false,
                                 default = nil)
  if valid_594017 != nil:
    section.add "MaxResults", valid_594017
  var valid_594018 = query.getOrDefault("NextToken")
  valid_594018 = validateParameter(valid_594018, JString, required = false,
                                 default = nil)
  if valid_594018 != nil:
    section.add "NextToken", valid_594018
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
  var valid_594019 = header.getOrDefault("X-Amz-Signature")
  valid_594019 = validateParameter(valid_594019, JString, required = false,
                                 default = nil)
  if valid_594019 != nil:
    section.add "X-Amz-Signature", valid_594019
  var valid_594020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594020 = validateParameter(valid_594020, JString, required = false,
                                 default = nil)
  if valid_594020 != nil:
    section.add "X-Amz-Content-Sha256", valid_594020
  var valid_594021 = header.getOrDefault("X-Amz-Date")
  valid_594021 = validateParameter(valid_594021, JString, required = false,
                                 default = nil)
  if valid_594021 != nil:
    section.add "X-Amz-Date", valid_594021
  var valid_594022 = header.getOrDefault("X-Amz-Credential")
  valid_594022 = validateParameter(valid_594022, JString, required = false,
                                 default = nil)
  if valid_594022 != nil:
    section.add "X-Amz-Credential", valid_594022
  var valid_594023 = header.getOrDefault("X-Amz-Security-Token")
  valid_594023 = validateParameter(valid_594023, JString, required = false,
                                 default = nil)
  if valid_594023 != nil:
    section.add "X-Amz-Security-Token", valid_594023
  var valid_594024 = header.getOrDefault("X-Amz-Algorithm")
  valid_594024 = validateParameter(valid_594024, JString, required = false,
                                 default = nil)
  if valid_594024 != nil:
    section.add "X-Amz-Algorithm", valid_594024
  var valid_594025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594025 = validateParameter(valid_594025, JString, required = false,
                                 default = nil)
  if valid_594025 != nil:
    section.add "X-Amz-SignedHeaders", valid_594025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594027: Call_ListChangeSets_594014; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the list of change sets owned by the account being used to make the call. You can filter this list by providing any combination of <code>entityId</code>, <code>ChangeSetName</code>, and status. If you provide more than one filter, the API operation applies a logical AND between the filters.</p> <p>You can describe a change during the 60-day request history retention period for API calls.</p>
  ## 
  let valid = call_594027.validator(path, query, header, formData, body)
  let scheme = call_594027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594027.url(scheme.get, call_594027.host, call_594027.base,
                         call_594027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594027, url, valid)

proc call*(call_594028: Call_ListChangeSets_594014; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listChangeSets
  ## <p>Returns the list of change sets owned by the account being used to make the call. You can filter this list by providing any combination of <code>entityId</code>, <code>ChangeSetName</code>, and status. If you provide more than one filter, the API operation applies a logical AND between the filters.</p> <p>You can describe a change during the 60-day request history retention period for API calls.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594029 = newJObject()
  var body_594030 = newJObject()
  add(query_594029, "MaxResults", newJString(MaxResults))
  add(query_594029, "NextToken", newJString(NextToken))
  if body != nil:
    body_594030 = body
  result = call_594028.call(nil, query_594029, nil, nil, body_594030)

var listChangeSets* = Call_ListChangeSets_594014(name: "listChangeSets",
    meth: HttpMethod.HttpPost, host: "catalog.marketplace.amazonaws.com",
    route: "/ListChangeSets", validator: validate_ListChangeSets_594015, base: "/",
    url: url_ListChangeSets_594016, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntities_594031 = ref object of OpenApiRestCall_593389
proc url_ListEntities_594033(protocol: Scheme; host: string; base: string;
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

proc validate_ListEntities_594032(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594034 = query.getOrDefault("MaxResults")
  valid_594034 = validateParameter(valid_594034, JString, required = false,
                                 default = nil)
  if valid_594034 != nil:
    section.add "MaxResults", valid_594034
  var valid_594035 = query.getOrDefault("NextToken")
  valid_594035 = validateParameter(valid_594035, JString, required = false,
                                 default = nil)
  if valid_594035 != nil:
    section.add "NextToken", valid_594035
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
  var valid_594036 = header.getOrDefault("X-Amz-Signature")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-Signature", valid_594036
  var valid_594037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "X-Amz-Content-Sha256", valid_594037
  var valid_594038 = header.getOrDefault("X-Amz-Date")
  valid_594038 = validateParameter(valid_594038, JString, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "X-Amz-Date", valid_594038
  var valid_594039 = header.getOrDefault("X-Amz-Credential")
  valid_594039 = validateParameter(valid_594039, JString, required = false,
                                 default = nil)
  if valid_594039 != nil:
    section.add "X-Amz-Credential", valid_594039
  var valid_594040 = header.getOrDefault("X-Amz-Security-Token")
  valid_594040 = validateParameter(valid_594040, JString, required = false,
                                 default = nil)
  if valid_594040 != nil:
    section.add "X-Amz-Security-Token", valid_594040
  var valid_594041 = header.getOrDefault("X-Amz-Algorithm")
  valid_594041 = validateParameter(valid_594041, JString, required = false,
                                 default = nil)
  if valid_594041 != nil:
    section.add "X-Amz-Algorithm", valid_594041
  var valid_594042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594042 = validateParameter(valid_594042, JString, required = false,
                                 default = nil)
  if valid_594042 != nil:
    section.add "X-Amz-SignedHeaders", valid_594042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594044: Call_ListEntities_594031; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the list of entities of a given type.
  ## 
  let valid = call_594044.validator(path, query, header, formData, body)
  let scheme = call_594044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594044.url(scheme.get, call_594044.host, call_594044.base,
                         call_594044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594044, url, valid)

proc call*(call_594045: Call_ListEntities_594031; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEntities
  ## Provides the list of entities of a given type.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594046 = newJObject()
  var body_594047 = newJObject()
  add(query_594046, "MaxResults", newJString(MaxResults))
  add(query_594046, "NextToken", newJString(NextToken))
  if body != nil:
    body_594047 = body
  result = call_594045.call(nil, query_594046, nil, nil, body_594047)

var listEntities* = Call_ListEntities_594031(name: "listEntities",
    meth: HttpMethod.HttpPost, host: "catalog.marketplace.amazonaws.com",
    route: "/ListEntities", validator: validate_ListEntities_594032, base: "/",
    url: url_ListEntities_594033, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartChangeSet_594048 = ref object of OpenApiRestCall_593389
proc url_StartChangeSet_594050(protocol: Scheme; host: string; base: string;
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

proc validate_StartChangeSet_594049(path: JsonNode; query: JsonNode;
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
  var valid_594051 = header.getOrDefault("X-Amz-Signature")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Signature", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Content-Sha256", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Date")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Date", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Credential")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Credential", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-Security-Token")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Security-Token", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-Algorithm")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Algorithm", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-SignedHeaders", valid_594057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594059: Call_StartChangeSet_594048; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation allows you to request changes in your entities.
  ## 
  let valid = call_594059.validator(path, query, header, formData, body)
  let scheme = call_594059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594059.url(scheme.get, call_594059.host, call_594059.base,
                         call_594059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594059, url, valid)

proc call*(call_594060: Call_StartChangeSet_594048; body: JsonNode): Recallable =
  ## startChangeSet
  ## This operation allows you to request changes in your entities.
  ##   body: JObject (required)
  var body_594061 = newJObject()
  if body != nil:
    body_594061 = body
  result = call_594060.call(nil, nil, nil, nil, body_594061)

var startChangeSet* = Call_StartChangeSet_594048(name: "startChangeSet",
    meth: HttpMethod.HttpPost, host: "catalog.marketplace.amazonaws.com",
    route: "/StartChangeSet", validator: validate_StartChangeSet_594049, base: "/",
    url: url_StartChangeSet_594050, schemes: {Scheme.Https, Scheme.Http})
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
