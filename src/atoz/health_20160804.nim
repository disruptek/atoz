
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Health APIs and Notifications
## version: 2016-08-04
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Health</fullname> <p>The AWS Health API provides programmatic access to the AWS Health information that is presented in the <a href="https://phd.aws.amazon.com/phd/home#/">AWS Personal Health Dashboard</a>. You can get information about events that affect your AWS resources:</p> <ul> <li> <p> <a>DescribeEvents</a>: Summary information about events.</p> </li> <li> <p> <a>DescribeEventDetails</a>: Detailed information about one or more events.</p> </li> <li> <p> <a>DescribeAffectedEntities</a>: Information about AWS resources that are affected by one or more events.</p> </li> </ul> <p>In addition, these operations provide information about event types and summary counts of events or affected entities:</p> <ul> <li> <p> <a>DescribeEventTypes</a>: Information about the kinds of events that AWS Health tracks.</p> </li> <li> <p> <a>DescribeEventAggregates</a>: A count of the number of events that meet specified criteria.</p> </li> <li> <p> <a>DescribeEntityAggregates</a>: A count of the number of affected entities that meet specified criteria.</p> </li> </ul> <p>The Health API requires a Business or Enterprise support plan from <a href="http://aws.amazon.com/premiumsupport/">AWS Support</a>. Calling the Health API from an account that does not have a Business or Enterprise support plan causes a <code>SubscriptionRequiredException</code>. </p> <p>For authentication of requests, AWS Health uses the <a href="https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html">Signature Version 4 Signing Process</a>.</p> <p>See the <a href="https://docs.aws.amazon.com/health/latest/ug/what-is-aws-health.html">AWS Health User Guide</a> for information about how to use the API.</p> <p> <b>Service Endpoint</b> </p> <p>The HTTP endpoint for the AWS Health API is:</p> <ul> <li> <p>https://health.us-east-1.amazonaws.com </p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/health/
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
  awsServers = {Scheme.Http: {"cn-northwest-1": "health.cn-northwest-1.amazonaws.com.cn",
                           "cn-north-1": "health.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "health.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "health.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "health"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_DescribeAffectedEntities_599705 = ref object of OpenApiRestCall_599368
proc url_DescribeAffectedEntities_599707(protocol: Scheme; host: string;
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

proc validate_DescribeAffectedEntities_599706(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of entities that have been affected by the specified events, based on the specified filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service. Events that have impact beyond that of the affected entities, or where the extent of impact is unknown, include at least one entity indicating this.</p> <p>At least one event ARN is required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_599819 = query.getOrDefault("maxResults")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "maxResults", valid_599819
  var valid_599820 = query.getOrDefault("nextToken")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "nextToken", valid_599820
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
  var valid_599821 = header.getOrDefault("X-Amz-Date")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Date", valid_599821
  var valid_599822 = header.getOrDefault("X-Amz-Security-Token")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "X-Amz-Security-Token", valid_599822
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599836 = header.getOrDefault("X-Amz-Target")
  valid_599836 = validateParameter(valid_599836, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeAffectedEntities"))
  if valid_599836 != nil:
    section.add "X-Amz-Target", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Content-Sha256", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Algorithm")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Algorithm", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Signature")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Signature", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-SignedHeaders", valid_599840
  var valid_599841 = header.getOrDefault("X-Amz-Credential")
  valid_599841 = validateParameter(valid_599841, JString, required = false,
                                 default = nil)
  if valid_599841 != nil:
    section.add "X-Amz-Credential", valid_599841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599865: Call_DescribeAffectedEntities_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of entities that have been affected by the specified events, based on the specified filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service. Events that have impact beyond that of the affected entities, or where the extent of impact is unknown, include at least one entity indicating this.</p> <p>At least one event ARN is required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p>
  ## 
  let valid = call_599865.validator(path, query, header, formData, body)
  let scheme = call_599865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599865.url(scheme.get, call_599865.host, call_599865.base,
                         call_599865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599865, url, valid)

proc call*(call_599936: Call_DescribeAffectedEntities_599705; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeAffectedEntities
  ## <p>Returns a list of entities that have been affected by the specified events, based on the specified filter criteria. Entities can refer to individual customer resources, groups of customer resources, or any other construct, depending on the AWS service. Events that have impact beyond that of the affected entities, or where the extent of impact is unknown, include at least one entity indicating this.</p> <p>At least one event ARN is required. Results are sorted by the <code>lastUpdatedTime</code> of the entity, starting with the most recent.</p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599937 = newJObject()
  var body_599939 = newJObject()
  add(query_599937, "maxResults", newJString(maxResults))
  add(query_599937, "nextToken", newJString(nextToken))
  if body != nil:
    body_599939 = body
  result = call_599936.call(nil, query_599937, nil, nil, body_599939)

var describeAffectedEntities* = Call_DescribeAffectedEntities_599705(
    name: "describeAffectedEntities", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeAffectedEntities",
    validator: validate_DescribeAffectedEntities_599706, base: "/",
    url: url_DescribeAffectedEntities_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEntityAggregates_599978 = ref object of OpenApiRestCall_599368
proc url_DescribeEntityAggregates_599980(protocol: Scheme; host: string;
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

proc validate_DescribeEntityAggregates_599979(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the number of entities that are affected by each of the specified events. If no events are specified, the counts of all affected entities are returned.
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
  var valid_599981 = header.getOrDefault("X-Amz-Date")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Date", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Security-Token")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Security-Token", valid_599982
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599983 = header.getOrDefault("X-Amz-Target")
  valid_599983 = validateParameter(valid_599983, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEntityAggregates"))
  if valid_599983 != nil:
    section.add "X-Amz-Target", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Content-Sha256", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Algorithm")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Algorithm", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-Signature")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-Signature", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-SignedHeaders", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-Credential")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-Credential", valid_599988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599990: Call_DescribeEntityAggregates_599978; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of entities that are affected by each of the specified events. If no events are specified, the counts of all affected entities are returned.
  ## 
  let valid = call_599990.validator(path, query, header, formData, body)
  let scheme = call_599990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599990.url(scheme.get, call_599990.host, call_599990.base,
                         call_599990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599990, url, valid)

proc call*(call_599991: Call_DescribeEntityAggregates_599978; body: JsonNode): Recallable =
  ## describeEntityAggregates
  ## Returns the number of entities that are affected by each of the specified events. If no events are specified, the counts of all affected entities are returned.
  ##   body: JObject (required)
  var body_599992 = newJObject()
  if body != nil:
    body_599992 = body
  result = call_599991.call(nil, nil, nil, nil, body_599992)

var describeEntityAggregates* = Call_DescribeEntityAggregates_599978(
    name: "describeEntityAggregates", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEntityAggregates",
    validator: validate_DescribeEntityAggregates_599979, base: "/",
    url: url_DescribeEntityAggregates_599980, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventAggregates_599993 = ref object of OpenApiRestCall_599368
proc url_DescribeEventAggregates_599995(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEventAggregates_599994(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the number of events of each event type (issue, scheduled change, and account notification). If no filter is specified, the counts of all events in each category are returned.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_599996 = query.getOrDefault("maxResults")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "maxResults", valid_599996
  var valid_599997 = query.getOrDefault("nextToken")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "nextToken", valid_599997
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
  var valid_599998 = header.getOrDefault("X-Amz-Date")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Date", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Security-Token")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Security-Token", valid_599999
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600000 = header.getOrDefault("X-Amz-Target")
  valid_600000 = validateParameter(valid_600000, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventAggregates"))
  if valid_600000 != nil:
    section.add "X-Amz-Target", valid_600000
  var valid_600001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Content-Sha256", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-Algorithm")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Algorithm", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-Signature")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Signature", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-SignedHeaders", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Credential")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Credential", valid_600005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600007: Call_DescribeEventAggregates_599993; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the number of events of each event type (issue, scheduled change, and account notification). If no filter is specified, the counts of all events in each category are returned.
  ## 
  let valid = call_600007.validator(path, query, header, formData, body)
  let scheme = call_600007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600007.url(scheme.get, call_600007.host, call_600007.base,
                         call_600007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600007, url, valid)

proc call*(call_600008: Call_DescribeEventAggregates_599993; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeEventAggregates
  ## Returns the number of events of each event type (issue, scheduled change, and account notification). If no filter is specified, the counts of all events in each category are returned.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600009 = newJObject()
  var body_600010 = newJObject()
  add(query_600009, "maxResults", newJString(maxResults))
  add(query_600009, "nextToken", newJString(nextToken))
  if body != nil:
    body_600010 = body
  result = call_600008.call(nil, query_600009, nil, nil, body_600010)

var describeEventAggregates* = Call_DescribeEventAggregates_599993(
    name: "describeEventAggregates", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventAggregates",
    validator: validate_DescribeEventAggregates_599994, base: "/",
    url: url_DescribeEventAggregates_599995, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventDetails_600011 = ref object of OpenApiRestCall_599368
proc url_DescribeEventDetails_600013(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEventDetails_600012(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns detailed information about one or more specified events. Information includes standard event data (region, service, etc., as returned by <a>DescribeEvents</a>), a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntities</a> operation.</p> <p>If a specified event cannot be retrieved, an error message is returned for that event.</p>
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
  var valid_600014 = header.getOrDefault("X-Amz-Date")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Date", valid_600014
  var valid_600015 = header.getOrDefault("X-Amz-Security-Token")
  valid_600015 = validateParameter(valid_600015, JString, required = false,
                                 default = nil)
  if valid_600015 != nil:
    section.add "X-Amz-Security-Token", valid_600015
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600016 = header.getOrDefault("X-Amz-Target")
  valid_600016 = validateParameter(valid_600016, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventDetails"))
  if valid_600016 != nil:
    section.add "X-Amz-Target", valid_600016
  var valid_600017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-Content-Sha256", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-Algorithm")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Algorithm", valid_600018
  var valid_600019 = header.getOrDefault("X-Amz-Signature")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-Signature", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-SignedHeaders", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-Credential")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-Credential", valid_600021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600023: Call_DescribeEventDetails_600011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns detailed information about one or more specified events. Information includes standard event data (region, service, etc., as returned by <a>DescribeEvents</a>), a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntities</a> operation.</p> <p>If a specified event cannot be retrieved, an error message is returned for that event.</p>
  ## 
  let valid = call_600023.validator(path, query, header, formData, body)
  let scheme = call_600023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600023.url(scheme.get, call_600023.host, call_600023.base,
                         call_600023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600023, url, valid)

proc call*(call_600024: Call_DescribeEventDetails_600011; body: JsonNode): Recallable =
  ## describeEventDetails
  ## <p>Returns detailed information about one or more specified events. Information includes standard event data (region, service, etc., as returned by <a>DescribeEvents</a>), a detailed event description, and possible additional metadata that depends upon the nature of the event. Affected entities are not included; to retrieve those, use the <a>DescribeAffectedEntities</a> operation.</p> <p>If a specified event cannot be retrieved, an error message is returned for that event.</p>
  ##   body: JObject (required)
  var body_600025 = newJObject()
  if body != nil:
    body_600025 = body
  result = call_600024.call(nil, nil, nil, nil, body_600025)

var describeEventDetails* = Call_DescribeEventDetails_600011(
    name: "describeEventDetails", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventDetails",
    validator: validate_DescribeEventDetails_600012, base: "/",
    url: url_DescribeEventDetails_600013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventTypes_600026 = ref object of OpenApiRestCall_599368
proc url_DescribeEventTypes_600028(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEventTypes_600027(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns the event types that meet the specified filter criteria. If no filter criteria are specified, all event types are returned, in no particular order.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600029 = query.getOrDefault("maxResults")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "maxResults", valid_600029
  var valid_600030 = query.getOrDefault("nextToken")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "nextToken", valid_600030
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
  var valid_600031 = header.getOrDefault("X-Amz-Date")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "X-Amz-Date", valid_600031
  var valid_600032 = header.getOrDefault("X-Amz-Security-Token")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "X-Amz-Security-Token", valid_600032
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600033 = header.getOrDefault("X-Amz-Target")
  valid_600033 = validateParameter(valid_600033, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEventTypes"))
  if valid_600033 != nil:
    section.add "X-Amz-Target", valid_600033
  var valid_600034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "X-Amz-Content-Sha256", valid_600034
  var valid_600035 = header.getOrDefault("X-Amz-Algorithm")
  valid_600035 = validateParameter(valid_600035, JString, required = false,
                                 default = nil)
  if valid_600035 != nil:
    section.add "X-Amz-Algorithm", valid_600035
  var valid_600036 = header.getOrDefault("X-Amz-Signature")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "X-Amz-Signature", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-SignedHeaders", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Credential")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Credential", valid_600038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600040: Call_DescribeEventTypes_600026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the event types that meet the specified filter criteria. If no filter criteria are specified, all event types are returned, in no particular order.
  ## 
  let valid = call_600040.validator(path, query, header, formData, body)
  let scheme = call_600040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600040.url(scheme.get, call_600040.host, call_600040.base,
                         call_600040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600040, url, valid)

proc call*(call_600041: Call_DescribeEventTypes_600026; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeEventTypes
  ## Returns the event types that meet the specified filter criteria. If no filter criteria are specified, all event types are returned, in no particular order.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600042 = newJObject()
  var body_600043 = newJObject()
  add(query_600042, "maxResults", newJString(maxResults))
  add(query_600042, "nextToken", newJString(nextToken))
  if body != nil:
    body_600043 = body
  result = call_600041.call(nil, query_600042, nil, nil, body_600043)

var describeEventTypes* = Call_DescribeEventTypes_600026(
    name: "describeEventTypes", meth: HttpMethod.HttpPost,
    host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEventTypes",
    validator: validate_DescribeEventTypes_600027, base: "/",
    url: url_DescribeEventTypes_600028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvents_600044 = ref object of OpenApiRestCall_599368
proc url_DescribeEvents_600046(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEvents_600045(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns information about events that meet the specified filter criteria. Events are returned in a summary form and do not include the detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeEventDetails</a> and <a>DescribeAffectedEntities</a> operations.</p> <p>If no filter criteria are specified, all events are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600047 = query.getOrDefault("maxResults")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "maxResults", valid_600047
  var valid_600048 = query.getOrDefault("nextToken")
  valid_600048 = validateParameter(valid_600048, JString, required = false,
                                 default = nil)
  if valid_600048 != nil:
    section.add "nextToken", valid_600048
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
  var valid_600049 = header.getOrDefault("X-Amz-Date")
  valid_600049 = validateParameter(valid_600049, JString, required = false,
                                 default = nil)
  if valid_600049 != nil:
    section.add "X-Amz-Date", valid_600049
  var valid_600050 = header.getOrDefault("X-Amz-Security-Token")
  valid_600050 = validateParameter(valid_600050, JString, required = false,
                                 default = nil)
  if valid_600050 != nil:
    section.add "X-Amz-Security-Token", valid_600050
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600051 = header.getOrDefault("X-Amz-Target")
  valid_600051 = validateParameter(valid_600051, JString, required = true, default = newJString(
      "AWSHealth_20160804.DescribeEvents"))
  if valid_600051 != nil:
    section.add "X-Amz-Target", valid_600051
  var valid_600052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Content-Sha256", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Algorithm")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Algorithm", valid_600053
  var valid_600054 = header.getOrDefault("X-Amz-Signature")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-Signature", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-SignedHeaders", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Credential")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Credential", valid_600056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600058: Call_DescribeEvents_600044; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about events that meet the specified filter criteria. Events are returned in a summary form and do not include the detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeEventDetails</a> and <a>DescribeAffectedEntities</a> operations.</p> <p>If no filter criteria are specified, all events are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p>
  ## 
  let valid = call_600058.validator(path, query, header, formData, body)
  let scheme = call_600058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600058.url(scheme.get, call_600058.host, call_600058.base,
                         call_600058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600058, url, valid)

proc call*(call_600059: Call_DescribeEvents_600044; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeEvents
  ## <p>Returns information about events that meet the specified filter criteria. Events are returned in a summary form and do not include the detailed description, any additional metadata that depends on the event type, or any affected resources. To retrieve that information, use the <a>DescribeEventDetails</a> and <a>DescribeAffectedEntities</a> operations.</p> <p>If no filter criteria are specified, all events are returned. Results are sorted by <code>lastModifiedTime</code>, starting with the most recent.</p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600060 = newJObject()
  var body_600061 = newJObject()
  add(query_600060, "maxResults", newJString(maxResults))
  add(query_600060, "nextToken", newJString(nextToken))
  if body != nil:
    body_600061 = body
  result = call_600059.call(nil, query_600060, nil, nil, body_600061)

var describeEvents* = Call_DescribeEvents_600044(name: "describeEvents",
    meth: HttpMethod.HttpPost, host: "health.amazonaws.com",
    route: "/#X-Amz-Target=AWSHealth_20160804.DescribeEvents",
    validator: validate_DescribeEvents_600045, base: "/", url: url_DescribeEvents_600046,
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
