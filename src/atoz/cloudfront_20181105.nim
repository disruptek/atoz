
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudFront
## version: 2018-11-05
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon CloudFront</fullname> <p>This is the <i>Amazon CloudFront API Reference</i>. This guide is for developers who need detailed information about CloudFront API actions, data types, and errors. For detailed information about CloudFront features, see the <i>Amazon CloudFront Developer Guide</i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cloudfront/
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn", "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "cloudfront"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateCloudFrontOriginAccessIdentity20181105_601984 = ref object of OpenApiRestCall_601389
proc url_CreateCloudFrontOriginAccessIdentity20181105_601986(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCloudFrontOriginAccessIdentity20181105_601985(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
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
  var valid_601987 = header.getOrDefault("X-Amz-Signature")
  valid_601987 = validateParameter(valid_601987, JString, required = false,
                                 default = nil)
  if valid_601987 != nil:
    section.add "X-Amz-Signature", valid_601987
  var valid_601988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601988 = validateParameter(valid_601988, JString, required = false,
                                 default = nil)
  if valid_601988 != nil:
    section.add "X-Amz-Content-Sha256", valid_601988
  var valid_601989 = header.getOrDefault("X-Amz-Date")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "X-Amz-Date", valid_601989
  var valid_601990 = header.getOrDefault("X-Amz-Credential")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Credential", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-Security-Token")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Security-Token", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Algorithm")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Algorithm", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-SignedHeaders", valid_601993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601995: Call_CreateCloudFrontOriginAccessIdentity20181105_601984;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ## 
  let valid = call_601995.validator(path, query, header, formData, body)
  let scheme = call_601995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601995.url(scheme.get, call_601995.host, call_601995.base,
                         call_601995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601995, url, valid)

proc call*(call_601996: Call_CreateCloudFrontOriginAccessIdentity20181105_601984;
          body: JsonNode): Recallable =
  ## createCloudFrontOriginAccessIdentity20181105
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ##   body: JObject (required)
  var body_601997 = newJObject()
  if body != nil:
    body_601997 = body
  result = call_601996.call(nil, nil, nil, nil, body_601997)

var createCloudFrontOriginAccessIdentity20181105* = Call_CreateCloudFrontOriginAccessIdentity20181105_601984(
    name: "createCloudFrontOriginAccessIdentity20181105",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/origin-access-identity/cloudfront",
    validator: validate_CreateCloudFrontOriginAccessIdentity20181105_601985,
    base: "/", url: url_CreateCloudFrontOriginAccessIdentity20181105_601986,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCloudFrontOriginAccessIdentities20181105_601727 = ref object of OpenApiRestCall_601389
proc url_ListCloudFrontOriginAccessIdentities20181105_601729(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCloudFrontOriginAccessIdentities20181105_601728(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists origin access identities.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   MaxItems: JString
  ##           : The maximum number of origin access identities you want in the response body. 
  section = newJObject()
  var valid_601841 = query.getOrDefault("Marker")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "Marker", valid_601841
  var valid_601842 = query.getOrDefault("MaxItems")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "MaxItems", valid_601842
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
  var valid_601843 = header.getOrDefault("X-Amz-Signature")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Signature", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Content-Sha256", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Date")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Date", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Credential")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Credential", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Security-Token")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Security-Token", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Algorithm")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Algorithm", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-SignedHeaders", valid_601849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601872: Call_ListCloudFrontOriginAccessIdentities20181105_601727;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists origin access identities.
  ## 
  let valid = call_601872.validator(path, query, header, formData, body)
  let scheme = call_601872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601872.url(scheme.get, call_601872.host, call_601872.base,
                         call_601872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601872, url, valid)

proc call*(call_601943: Call_ListCloudFrontOriginAccessIdentities20181105_601727;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listCloudFrontOriginAccessIdentities20181105
  ## Lists origin access identities.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   MaxItems: string
  ##           : The maximum number of origin access identities you want in the response body. 
  var query_601944 = newJObject()
  add(query_601944, "Marker", newJString(Marker))
  add(query_601944, "MaxItems", newJString(MaxItems))
  result = call_601943.call(nil, query_601944, nil, nil, nil)

var listCloudFrontOriginAccessIdentities20181105* = Call_ListCloudFrontOriginAccessIdentities20181105_601727(
    name: "listCloudFrontOriginAccessIdentities20181105",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/origin-access-identity/cloudfront",
    validator: validate_ListCloudFrontOriginAccessIdentities20181105_601728,
    base: "/", url: url_ListCloudFrontOriginAccessIdentities20181105_601729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistribution20181105_602013 = ref object of OpenApiRestCall_601389
proc url_CreateDistribution20181105_602015(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDistribution20181105_602014(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new web distribution. You create a CloudFront distribution to tell CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.</p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using <a>UpdateDistribution</a>, follow the steps included in the documentation to get the current configuration and then make your updates. This helps to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>If you are using Adobe Flash Media Server's RTMP protocol, you set up a different kind of CloudFront distribution. For more information, see <a>CreateStreamingDistribution</a>.</p>
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
  var valid_602016 = header.getOrDefault("X-Amz-Signature")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Signature", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Content-Sha256", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Date")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Date", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Credential")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Credential", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Security-Token")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Security-Token", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Algorithm")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Algorithm", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-SignedHeaders", valid_602022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602024: Call_CreateDistribution20181105_602013; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new web distribution. You create a CloudFront distribution to tell CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.</p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using <a>UpdateDistribution</a>, follow the steps included in the documentation to get the current configuration and then make your updates. This helps to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>If you are using Adobe Flash Media Server's RTMP protocol, you set up a different kind of CloudFront distribution. For more information, see <a>CreateStreamingDistribution</a>.</p>
  ## 
  let valid = call_602024.validator(path, query, header, formData, body)
  let scheme = call_602024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602024.url(scheme.get, call_602024.host, call_602024.base,
                         call_602024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602024, url, valid)

proc call*(call_602025: Call_CreateDistribution20181105_602013; body: JsonNode): Recallable =
  ## createDistribution20181105
  ## <p>Creates a new web distribution. You create a CloudFront distribution to tell CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.</p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using <a>UpdateDistribution</a>, follow the steps included in the documentation to get the current configuration and then make your updates. This helps to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>If you are using Adobe Flash Media Server's RTMP protocol, you set up a different kind of CloudFront distribution. For more information, see <a>CreateStreamingDistribution</a>.</p>
  ##   body: JObject (required)
  var body_602026 = newJObject()
  if body != nil:
    body_602026 = body
  result = call_602025.call(nil, nil, nil, nil, body_602026)

var createDistribution20181105* = Call_CreateDistribution20181105_602013(
    name: "createDistribution20181105", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/distribution",
    validator: validate_CreateDistribution20181105_602014, base: "/",
    url: url_CreateDistribution20181105_602015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributions20181105_601998 = ref object of OpenApiRestCall_601389
proc url_ListDistributions20181105_602000(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDistributions20181105_601999(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List distributions. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   MaxItems: JString
  ##           : The maximum number of distributions you want in the response body.
  section = newJObject()
  var valid_602001 = query.getOrDefault("Marker")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "Marker", valid_602001
  var valid_602002 = query.getOrDefault("MaxItems")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "MaxItems", valid_602002
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
  var valid_602003 = header.getOrDefault("X-Amz-Signature")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Signature", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Content-Sha256", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Date")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Date", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Credential")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Credential", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Security-Token")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Security-Token", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Algorithm")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Algorithm", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-SignedHeaders", valid_602009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602010: Call_ListDistributions20181105_601998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List distributions. 
  ## 
  let valid = call_602010.validator(path, query, header, formData, body)
  let scheme = call_602010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602010.url(scheme.get, call_602010.host, call_602010.base,
                         call_602010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602010, url, valid)

proc call*(call_602011: Call_ListDistributions20181105_601998; Marker: string = "";
          MaxItems: string = ""): Recallable =
  ## listDistributions20181105
  ## List distributions. 
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   MaxItems: string
  ##           : The maximum number of distributions you want in the response body.
  var query_602012 = newJObject()
  add(query_602012, "Marker", newJString(Marker))
  add(query_602012, "MaxItems", newJString(MaxItems))
  result = call_602011.call(nil, query_602012, nil, nil, nil)

var listDistributions20181105* = Call_ListDistributions20181105_601998(
    name: "listDistributions20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/distribution",
    validator: validate_ListDistributions20181105_601999, base: "/",
    url: url_ListDistributions20181105_602000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistributionWithTags20181105_602027 = ref object of OpenApiRestCall_601389
proc url_CreateDistributionWithTags20181105_602029(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDistributionWithTags20181105_602028(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new distribution with tags.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   WithTags: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `WithTags` field"
  var valid_602030 = query.getOrDefault("WithTags")
  valid_602030 = validateParameter(valid_602030, JBool, required = true, default = nil)
  if valid_602030 != nil:
    section.add "WithTags", valid_602030
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
  var valid_602031 = header.getOrDefault("X-Amz-Signature")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Signature", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Content-Sha256", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Date")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Date", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Credential")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Credential", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Security-Token")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Security-Token", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Algorithm")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Algorithm", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-SignedHeaders", valid_602037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602039: Call_CreateDistributionWithTags20181105_602027;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new distribution with tags.
  ## 
  let valid = call_602039.validator(path, query, header, formData, body)
  let scheme = call_602039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602039.url(scheme.get, call_602039.host, call_602039.base,
                         call_602039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602039, url, valid)

proc call*(call_602040: Call_CreateDistributionWithTags20181105_602027;
          body: JsonNode; WithTags: bool): Recallable =
  ## createDistributionWithTags20181105
  ## Create a new distribution with tags.
  ##   body: JObject (required)
  ##   WithTags: bool (required)
  var query_602041 = newJObject()
  var body_602042 = newJObject()
  if body != nil:
    body_602042 = body
  add(query_602041, "WithTags", newJBool(WithTags))
  result = call_602040.call(nil, query_602041, nil, nil, body_602042)

var createDistributionWithTags20181105* = Call_CreateDistributionWithTags20181105_602027(
    name: "createDistributionWithTags20181105", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/distribution#WithTags",
    validator: validate_CreateDistributionWithTags20181105_602028, base: "/",
    url: url_CreateDistributionWithTags20181105_602029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFieldLevelEncryptionConfig20181105_602058 = ref object of OpenApiRestCall_601389
proc url_CreateFieldLevelEncryptionConfig20181105_602060(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFieldLevelEncryptionConfig20181105_602059(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new field-level encryption configuration.
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
  var valid_602061 = header.getOrDefault("X-Amz-Signature")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Signature", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Content-Sha256", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Date")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Date", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Credential")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Credential", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Security-Token")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Security-Token", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-Algorithm")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Algorithm", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-SignedHeaders", valid_602067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602069: Call_CreateFieldLevelEncryptionConfig20181105_602058;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new field-level encryption configuration.
  ## 
  let valid = call_602069.validator(path, query, header, formData, body)
  let scheme = call_602069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602069.url(scheme.get, call_602069.host, call_602069.base,
                         call_602069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602069, url, valid)

proc call*(call_602070: Call_CreateFieldLevelEncryptionConfig20181105_602058;
          body: JsonNode): Recallable =
  ## createFieldLevelEncryptionConfig20181105
  ## Create a new field-level encryption configuration.
  ##   body: JObject (required)
  var body_602071 = newJObject()
  if body != nil:
    body_602071 = body
  result = call_602070.call(nil, nil, nil, nil, body_602071)

var createFieldLevelEncryptionConfig20181105* = Call_CreateFieldLevelEncryptionConfig20181105_602058(
    name: "createFieldLevelEncryptionConfig20181105", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/field-level-encryption",
    validator: validate_CreateFieldLevelEncryptionConfig20181105_602059,
    base: "/", url: url_CreateFieldLevelEncryptionConfig20181105_602060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFieldLevelEncryptionConfigs20181105_602043 = ref object of OpenApiRestCall_601389
proc url_ListFieldLevelEncryptionConfigs20181105_602045(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFieldLevelEncryptionConfigs20181105_602044(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all field-level encryption configurations that have been created in CloudFront for this account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of configurations. The results include configurations in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last configuration on that page). 
  ##   MaxItems: JString
  ##           : The maximum number of field-level encryption configurations you want in the response body. 
  section = newJObject()
  var valid_602046 = query.getOrDefault("Marker")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "Marker", valid_602046
  var valid_602047 = query.getOrDefault("MaxItems")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "MaxItems", valid_602047
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
  var valid_602048 = header.getOrDefault("X-Amz-Signature")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Signature", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Content-Sha256", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Date")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Date", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Credential")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Credential", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Security-Token")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Security-Token", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-Algorithm")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Algorithm", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-SignedHeaders", valid_602054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602055: Call_ListFieldLevelEncryptionConfigs20181105_602043;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List all field-level encryption configurations that have been created in CloudFront for this account.
  ## 
  let valid = call_602055.validator(path, query, header, formData, body)
  let scheme = call_602055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602055.url(scheme.get, call_602055.host, call_602055.base,
                         call_602055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602055, url, valid)

proc call*(call_602056: Call_ListFieldLevelEncryptionConfigs20181105_602043;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listFieldLevelEncryptionConfigs20181105
  ## List all field-level encryption configurations that have been created in CloudFront for this account.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of configurations. The results include configurations in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last configuration on that page). 
  ##   MaxItems: string
  ##           : The maximum number of field-level encryption configurations you want in the response body. 
  var query_602057 = newJObject()
  add(query_602057, "Marker", newJString(Marker))
  add(query_602057, "MaxItems", newJString(MaxItems))
  result = call_602056.call(nil, query_602057, nil, nil, nil)

var listFieldLevelEncryptionConfigs20181105* = Call_ListFieldLevelEncryptionConfigs20181105_602043(
    name: "listFieldLevelEncryptionConfigs20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/field-level-encryption",
    validator: validate_ListFieldLevelEncryptionConfigs20181105_602044, base: "/",
    url: url_ListFieldLevelEncryptionConfigs20181105_602045,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFieldLevelEncryptionProfile20181105_602087 = ref object of OpenApiRestCall_601389
proc url_CreateFieldLevelEncryptionProfile20181105_602089(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFieldLevelEncryptionProfile20181105_602088(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a field-level encryption profile.
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
  var valid_602090 = header.getOrDefault("X-Amz-Signature")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Signature", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Content-Sha256", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Date")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Date", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Credential")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Credential", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Security-Token")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Security-Token", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Algorithm")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Algorithm", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-SignedHeaders", valid_602096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602098: Call_CreateFieldLevelEncryptionProfile20181105_602087;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a field-level encryption profile.
  ## 
  let valid = call_602098.validator(path, query, header, formData, body)
  let scheme = call_602098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602098.url(scheme.get, call_602098.host, call_602098.base,
                         call_602098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602098, url, valid)

proc call*(call_602099: Call_CreateFieldLevelEncryptionProfile20181105_602087;
          body: JsonNode): Recallable =
  ## createFieldLevelEncryptionProfile20181105
  ## Create a field-level encryption profile.
  ##   body: JObject (required)
  var body_602100 = newJObject()
  if body != nil:
    body_602100 = body
  result = call_602099.call(nil, nil, nil, nil, body_602100)

var createFieldLevelEncryptionProfile20181105* = Call_CreateFieldLevelEncryptionProfile20181105_602087(
    name: "createFieldLevelEncryptionProfile20181105", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption-profile",
    validator: validate_CreateFieldLevelEncryptionProfile20181105_602088,
    base: "/", url: url_CreateFieldLevelEncryptionProfile20181105_602089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFieldLevelEncryptionProfiles20181105_602072 = ref object of OpenApiRestCall_601389
proc url_ListFieldLevelEncryptionProfiles20181105_602074(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFieldLevelEncryptionProfiles20181105_602073(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Request a list of field-level encryption profiles that have been created in CloudFront for this account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of profiles. The results include profiles in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last profile on that page). 
  ##   MaxItems: JString
  ##           : The maximum number of field-level encryption profiles you want in the response body. 
  section = newJObject()
  var valid_602075 = query.getOrDefault("Marker")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "Marker", valid_602075
  var valid_602076 = query.getOrDefault("MaxItems")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "MaxItems", valid_602076
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
  var valid_602077 = header.getOrDefault("X-Amz-Signature")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Signature", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Content-Sha256", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Date")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Date", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Credential")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Credential", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-Security-Token")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Security-Token", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-Algorithm")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-Algorithm", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-SignedHeaders", valid_602083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602084: Call_ListFieldLevelEncryptionProfiles20181105_602072;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Request a list of field-level encryption profiles that have been created in CloudFront for this account.
  ## 
  let valid = call_602084.validator(path, query, header, formData, body)
  let scheme = call_602084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602084.url(scheme.get, call_602084.host, call_602084.base,
                         call_602084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602084, url, valid)

proc call*(call_602085: Call_ListFieldLevelEncryptionProfiles20181105_602072;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listFieldLevelEncryptionProfiles20181105
  ## Request a list of field-level encryption profiles that have been created in CloudFront for this account.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of profiles. The results include profiles in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last profile on that page). 
  ##   MaxItems: string
  ##           : The maximum number of field-level encryption profiles you want in the response body. 
  var query_602086 = newJObject()
  add(query_602086, "Marker", newJString(Marker))
  add(query_602086, "MaxItems", newJString(MaxItems))
  result = call_602085.call(nil, query_602086, nil, nil, nil)

var listFieldLevelEncryptionProfiles20181105* = Call_ListFieldLevelEncryptionProfiles20181105_602072(
    name: "listFieldLevelEncryptionProfiles20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption-profile",
    validator: validate_ListFieldLevelEncryptionProfiles20181105_602073,
    base: "/", url: url_ListFieldLevelEncryptionProfiles20181105_602074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInvalidation20181105_602132 = ref object of OpenApiRestCall_601389
proc url_CreateInvalidation20181105_602134(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateInvalidation20181105_602133(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new invalidation. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
  ##                 : The distribution's id.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DistributionId` field"
  var valid_602135 = path.getOrDefault("DistributionId")
  valid_602135 = validateParameter(valid_602135, JString, required = true,
                                 default = nil)
  if valid_602135 != nil:
    section.add "DistributionId", valid_602135
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
  var valid_602136 = header.getOrDefault("X-Amz-Signature")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Signature", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Content-Sha256", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Date")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Date", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Credential")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Credential", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Security-Token")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Security-Token", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Algorithm")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Algorithm", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-SignedHeaders", valid_602142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602144: Call_CreateInvalidation20181105_602132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new invalidation. 
  ## 
  let valid = call_602144.validator(path, query, header, formData, body)
  let scheme = call_602144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602144.url(scheme.get, call_602144.host, call_602144.base,
                         call_602144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602144, url, valid)

proc call*(call_602145: Call_CreateInvalidation20181105_602132;
          DistributionId: string; body: JsonNode): Recallable =
  ## createInvalidation20181105
  ## Create a new invalidation. 
  ##   DistributionId: string (required)
  ##                 : The distribution's id.
  ##   body: JObject (required)
  var path_602146 = newJObject()
  var body_602147 = newJObject()
  add(path_602146, "DistributionId", newJString(DistributionId))
  if body != nil:
    body_602147 = body
  result = call_602145.call(path_602146, nil, nil, nil, body_602147)

var createInvalidation20181105* = Call_CreateInvalidation20181105_602132(
    name: "createInvalidation20181105", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/distribution/{DistributionId}/invalidation",
    validator: validate_CreateInvalidation20181105_602133, base: "/",
    url: url_CreateInvalidation20181105_602134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvalidations20181105_602101 = ref object of OpenApiRestCall_601389
proc url_ListInvalidations20181105_602103(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListInvalidations20181105_602102(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists invalidation batches. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
  ##                 : The distribution's ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DistributionId` field"
  var valid_602118 = path.getOrDefault("DistributionId")
  valid_602118 = validateParameter(valid_602118, JString, required = true,
                                 default = nil)
  if valid_602118 != nil:
    section.add "DistributionId", valid_602118
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: JString
  ##           : The maximum number of invalidation batches that you want in the response body.
  section = newJObject()
  var valid_602119 = query.getOrDefault("Marker")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "Marker", valid_602119
  var valid_602120 = query.getOrDefault("MaxItems")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "MaxItems", valid_602120
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
  var valid_602121 = header.getOrDefault("X-Amz-Signature")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Signature", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Content-Sha256", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Date")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Date", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Credential")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Credential", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Security-Token")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Security-Token", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Algorithm")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Algorithm", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-SignedHeaders", valid_602127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602128: Call_ListInvalidations20181105_602101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists invalidation batches. 
  ## 
  let valid = call_602128.validator(path, query, header, formData, body)
  let scheme = call_602128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602128.url(scheme.get, call_602128.host, call_602128.base,
                         call_602128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602128, url, valid)

proc call*(call_602129: Call_ListInvalidations20181105_602101;
          DistributionId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listInvalidations20181105
  ## Lists invalidation batches. 
  ##   Marker: string
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: string
  ##           : The maximum number of invalidation batches that you want in the response body.
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  var path_602130 = newJObject()
  var query_602131 = newJObject()
  add(query_602131, "Marker", newJString(Marker))
  add(query_602131, "MaxItems", newJString(MaxItems))
  add(path_602130, "DistributionId", newJString(DistributionId))
  result = call_602129.call(path_602130, query_602131, nil, nil, nil)

var listInvalidations20181105* = Call_ListInvalidations20181105_602101(
    name: "listInvalidations20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/distribution/{DistributionId}/invalidation",
    validator: validate_ListInvalidations20181105_602102, base: "/",
    url: url_ListInvalidations20181105_602103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePublicKey20181105_602163 = ref object of OpenApiRestCall_601389
proc url_CreatePublicKey20181105_602165(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePublicKey20181105_602164(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Add a new public key to CloudFront to use, for example, for field-level encryption. You can add a maximum of 10 public keys with one AWS account.
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
  var valid_602166 = header.getOrDefault("X-Amz-Signature")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Signature", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Content-Sha256", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Date")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Date", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Credential")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Credential", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Security-Token")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Security-Token", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-Algorithm")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-Algorithm", valid_602171
  var valid_602172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-SignedHeaders", valid_602172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602174: Call_CreatePublicKey20181105_602163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a new public key to CloudFront to use, for example, for field-level encryption. You can add a maximum of 10 public keys with one AWS account.
  ## 
  let valid = call_602174.validator(path, query, header, formData, body)
  let scheme = call_602174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602174.url(scheme.get, call_602174.host, call_602174.base,
                         call_602174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602174, url, valid)

proc call*(call_602175: Call_CreatePublicKey20181105_602163; body: JsonNode): Recallable =
  ## createPublicKey20181105
  ## Add a new public key to CloudFront to use, for example, for field-level encryption. You can add a maximum of 10 public keys with one AWS account.
  ##   body: JObject (required)
  var body_602176 = newJObject()
  if body != nil:
    body_602176 = body
  result = call_602175.call(nil, nil, nil, nil, body_602176)

var createPublicKey20181105* = Call_CreatePublicKey20181105_602163(
    name: "createPublicKey20181105", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/public-key",
    validator: validate_CreatePublicKey20181105_602164, base: "/",
    url: url_CreatePublicKey20181105_602165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublicKeys20181105_602148 = ref object of OpenApiRestCall_601389
proc url_ListPublicKeys20181105_602150(protocol: Scheme; host: string; base: string;
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

proc validate_ListPublicKeys20181105_602149(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all public keys that have been added to CloudFront for this account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of public keys. The results include public keys in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last public key on that page). 
  ##   MaxItems: JString
  ##           : The maximum number of public keys you want in the response body. 
  section = newJObject()
  var valid_602151 = query.getOrDefault("Marker")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "Marker", valid_602151
  var valid_602152 = query.getOrDefault("MaxItems")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "MaxItems", valid_602152
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
  var valid_602153 = header.getOrDefault("X-Amz-Signature")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Signature", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Content-Sha256", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Date")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Date", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Credential")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Credential", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Security-Token")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Security-Token", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Algorithm")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Algorithm", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-SignedHeaders", valid_602159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602160: Call_ListPublicKeys20181105_602148; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all public keys that have been added to CloudFront for this account.
  ## 
  let valid = call_602160.validator(path, query, header, formData, body)
  let scheme = call_602160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602160.url(scheme.get, call_602160.host, call_602160.base,
                         call_602160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602160, url, valid)

proc call*(call_602161: Call_ListPublicKeys20181105_602148; Marker: string = "";
          MaxItems: string = ""): Recallable =
  ## listPublicKeys20181105
  ## List all public keys that have been added to CloudFront for this account.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of public keys. The results include public keys in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last public key on that page). 
  ##   MaxItems: string
  ##           : The maximum number of public keys you want in the response body. 
  var query_602162 = newJObject()
  add(query_602162, "Marker", newJString(Marker))
  add(query_602162, "MaxItems", newJString(MaxItems))
  result = call_602161.call(nil, query_602162, nil, nil, nil)

var listPublicKeys20181105* = Call_ListPublicKeys20181105_602148(
    name: "listPublicKeys20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/public-key",
    validator: validate_ListPublicKeys20181105_602149, base: "/",
    url: url_ListPublicKeys20181105_602150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistribution20181105_602192 = ref object of OpenApiRestCall_601389
proc url_CreateStreamingDistribution20181105_602194(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStreamingDistribution20181105_602193(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
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
  var valid_602195 = header.getOrDefault("X-Amz-Signature")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Signature", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Content-Sha256", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Date")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Date", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Credential")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Credential", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Security-Token")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Security-Token", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Algorithm")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Algorithm", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-SignedHeaders", valid_602201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602203: Call_CreateStreamingDistribution20181105_602192;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ## 
  let valid = call_602203.validator(path, query, header, formData, body)
  let scheme = call_602203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602203.url(scheme.get, call_602203.host, call_602203.base,
                         call_602203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602203, url, valid)

proc call*(call_602204: Call_CreateStreamingDistribution20181105_602192;
          body: JsonNode): Recallable =
  ## createStreamingDistribution20181105
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ##   body: JObject (required)
  var body_602205 = newJObject()
  if body != nil:
    body_602205 = body
  result = call_602204.call(nil, nil, nil, nil, body_602205)

var createStreamingDistribution20181105* = Call_CreateStreamingDistribution20181105_602192(
    name: "createStreamingDistribution20181105", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/streaming-distribution",
    validator: validate_CreateStreamingDistribution20181105_602193, base: "/",
    url: url_CreateStreamingDistribution20181105_602194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStreamingDistributions20181105_602177 = ref object of OpenApiRestCall_601389
proc url_ListStreamingDistributions20181105_602179(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListStreamingDistributions20181105_602178(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List streaming distributions. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   MaxItems: JString
  ##           : The value that you provided for the <code>MaxItems</code> request parameter.
  section = newJObject()
  var valid_602180 = query.getOrDefault("Marker")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "Marker", valid_602180
  var valid_602181 = query.getOrDefault("MaxItems")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "MaxItems", valid_602181
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
  var valid_602182 = header.getOrDefault("X-Amz-Signature")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Signature", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Content-Sha256", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Date")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Date", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-Credential")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Credential", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-Security-Token")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-Security-Token", valid_602186
  var valid_602187 = header.getOrDefault("X-Amz-Algorithm")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "X-Amz-Algorithm", valid_602187
  var valid_602188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-SignedHeaders", valid_602188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602189: Call_ListStreamingDistributions20181105_602177;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List streaming distributions. 
  ## 
  let valid = call_602189.validator(path, query, header, formData, body)
  let scheme = call_602189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602189.url(scheme.get, call_602189.host, call_602189.base,
                         call_602189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602189, url, valid)

proc call*(call_602190: Call_ListStreamingDistributions20181105_602177;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listStreamingDistributions20181105
  ## List streaming distributions. 
  ##   Marker: string
  ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   MaxItems: string
  ##           : The value that you provided for the <code>MaxItems</code> request parameter.
  var query_602191 = newJObject()
  add(query_602191, "Marker", newJString(Marker))
  add(query_602191, "MaxItems", newJString(MaxItems))
  result = call_602190.call(nil, query_602191, nil, nil, nil)

var listStreamingDistributions20181105* = Call_ListStreamingDistributions20181105_602177(
    name: "listStreamingDistributions20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/streaming-distribution",
    validator: validate_ListStreamingDistributions20181105_602178, base: "/",
    url: url_ListStreamingDistributions20181105_602179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistributionWithTags20181105_602206 = ref object of OpenApiRestCall_601389
proc url_CreateStreamingDistributionWithTags20181105_602208(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStreamingDistributionWithTags20181105_602207(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new streaming distribution with tags.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   WithTags: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `WithTags` field"
  var valid_602209 = query.getOrDefault("WithTags")
  valid_602209 = validateParameter(valid_602209, JBool, required = true, default = nil)
  if valid_602209 != nil:
    section.add "WithTags", valid_602209
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
  var valid_602210 = header.getOrDefault("X-Amz-Signature")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Signature", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Content-Sha256", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Date")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Date", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Credential")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Credential", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Security-Token")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Security-Token", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Algorithm")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Algorithm", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-SignedHeaders", valid_602216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602218: Call_CreateStreamingDistributionWithTags20181105_602206;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new streaming distribution with tags.
  ## 
  let valid = call_602218.validator(path, query, header, formData, body)
  let scheme = call_602218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602218.url(scheme.get, call_602218.host, call_602218.base,
                         call_602218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602218, url, valid)

proc call*(call_602219: Call_CreateStreamingDistributionWithTags20181105_602206;
          body: JsonNode; WithTags: bool): Recallable =
  ## createStreamingDistributionWithTags20181105
  ## Create a new streaming distribution with tags.
  ##   body: JObject (required)
  ##   WithTags: bool (required)
  var query_602220 = newJObject()
  var body_602221 = newJObject()
  if body != nil:
    body_602221 = body
  add(query_602220, "WithTags", newJBool(WithTags))
  result = call_602219.call(nil, query_602220, nil, nil, body_602221)

var createStreamingDistributionWithTags20181105* = Call_CreateStreamingDistributionWithTags20181105_602206(
    name: "createStreamingDistributionWithTags20181105",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/streaming-distribution#WithTags",
    validator: validate_CreateStreamingDistributionWithTags20181105_602207,
    base: "/", url: url_CreateStreamingDistributionWithTags20181105_602208,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentity20181105_602222 = ref object of OpenApiRestCall_601389
proc url_GetCloudFrontOriginAccessIdentity20181105_602224(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-11-05/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCloudFrontOriginAccessIdentity20181105_602223(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the information about an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602225 = path.getOrDefault("Id")
  valid_602225 = validateParameter(valid_602225, JString, required = true,
                                 default = nil)
  if valid_602225 != nil:
    section.add "Id", valid_602225
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
  var valid_602226 = header.getOrDefault("X-Amz-Signature")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Signature", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Content-Sha256", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Date")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Date", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Credential")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Credential", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Security-Token")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Security-Token", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Algorithm")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Algorithm", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-SignedHeaders", valid_602232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602233: Call_GetCloudFrontOriginAccessIdentity20181105_602222;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the information about an origin access identity. 
  ## 
  let valid = call_602233.validator(path, query, header, formData, body)
  let scheme = call_602233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602233.url(scheme.get, call_602233.host, call_602233.base,
                         call_602233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602233, url, valid)

proc call*(call_602234: Call_GetCloudFrontOriginAccessIdentity20181105_602222;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentity20181105
  ## Get the information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID.
  var path_602235 = newJObject()
  add(path_602235, "Id", newJString(Id))
  result = call_602234.call(path_602235, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentity20181105* = Call_GetCloudFrontOriginAccessIdentity20181105_602222(
    name: "getCloudFrontOriginAccessIdentity20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/origin-access-identity/cloudfront/{Id}",
    validator: validate_GetCloudFrontOriginAccessIdentity20181105_602223,
    base: "/", url: url_GetCloudFrontOriginAccessIdentity20181105_602224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCloudFrontOriginAccessIdentity20181105_602236 = ref object of OpenApiRestCall_601389
proc url_DeleteCloudFrontOriginAccessIdentity20181105_602238(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-11-05/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCloudFrontOriginAccessIdentity20181105_602237(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Delete an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The origin access identity's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602239 = path.getOrDefault("Id")
  valid_602239 = validateParameter(valid_602239, JString, required = true,
                                 default = nil)
  if valid_602239 != nil:
    section.add "Id", valid_602239
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header you received from a previous <code>GET</code> or <code>PUT</code> request. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602240 = header.getOrDefault("X-Amz-Signature")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Signature", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Content-Sha256", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Date")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Date", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Credential")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Credential", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Security-Token")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Security-Token", valid_602244
  var valid_602245 = header.getOrDefault("If-Match")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "If-Match", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-Algorithm")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Algorithm", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-SignedHeaders", valid_602247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602248: Call_DeleteCloudFrontOriginAccessIdentity20181105_602236;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Delete an origin access identity. 
  ## 
  let valid = call_602248.validator(path, query, header, formData, body)
  let scheme = call_602248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602248.url(scheme.get, call_602248.host, call_602248.base,
                         call_602248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602248, url, valid)

proc call*(call_602249: Call_DeleteCloudFrontOriginAccessIdentity20181105_602236;
          Id: string): Recallable =
  ## deleteCloudFrontOriginAccessIdentity20181105
  ## Delete an origin access identity. 
  ##   Id: string (required)
  ##     : The origin access identity's ID.
  var path_602250 = newJObject()
  add(path_602250, "Id", newJString(Id))
  result = call_602249.call(path_602250, nil, nil, nil, nil)

var deleteCloudFrontOriginAccessIdentity20181105* = Call_DeleteCloudFrontOriginAccessIdentity20181105_602236(
    name: "deleteCloudFrontOriginAccessIdentity20181105",
    meth: HttpMethod.HttpDelete, host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/origin-access-identity/cloudfront/{Id}",
    validator: validate_DeleteCloudFrontOriginAccessIdentity20181105_602237,
    base: "/", url: url_DeleteCloudFrontOriginAccessIdentity20181105_602238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistribution20181105_602251 = ref object of OpenApiRestCall_601389
proc url_GetDistribution20181105_602253(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDistribution20181105_602252(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the information about a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602254 = path.getOrDefault("Id")
  valid_602254 = validateParameter(valid_602254, JString, required = true,
                                 default = nil)
  if valid_602254 != nil:
    section.add "Id", valid_602254
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
  var valid_602255 = header.getOrDefault("X-Amz-Signature")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Signature", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Content-Sha256", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Date")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Date", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Credential")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Credential", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-Security-Token")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Security-Token", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Algorithm")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Algorithm", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-SignedHeaders", valid_602261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602262: Call_GetDistribution20181105_602251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the information about a distribution. 
  ## 
  let valid = call_602262.validator(path, query, header, formData, body)
  let scheme = call_602262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602262.url(scheme.get, call_602262.host, call_602262.base,
                         call_602262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602262, url, valid)

proc call*(call_602263: Call_GetDistribution20181105_602251; Id: string): Recallable =
  ## getDistribution20181105
  ## Get the information about a distribution. 
  ##   Id: string (required)
  ##     : The distribution's ID.
  var path_602264 = newJObject()
  add(path_602264, "Id", newJString(Id))
  result = call_602263.call(path_602264, nil, nil, nil, nil)

var getDistribution20181105* = Call_GetDistribution20181105_602251(
    name: "getDistribution20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/distribution/{Id}",
    validator: validate_GetDistribution20181105_602252, base: "/",
    url: url_GetDistribution20181105_602253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDistribution20181105_602265 = ref object of OpenApiRestCall_601389
proc url_DeleteDistribution20181105_602267(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDistribution20181105_602266(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Delete a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602268 = path.getOrDefault("Id")
  valid_602268 = validateParameter(valid_602268, JString, required = true,
                                 default = nil)
  if valid_602268 != nil:
    section.add "Id", valid_602268
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when you disabled the distribution. For example: <code>E2QWRUHAPOMQZL</code>. 
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602269 = header.getOrDefault("X-Amz-Signature")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Signature", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Content-Sha256", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-Date")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Date", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Credential")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Credential", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Security-Token")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Security-Token", valid_602273
  var valid_602274 = header.getOrDefault("If-Match")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "If-Match", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-Algorithm")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Algorithm", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-SignedHeaders", valid_602276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602277: Call_DeleteDistribution20181105_602265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a distribution. 
  ## 
  let valid = call_602277.validator(path, query, header, formData, body)
  let scheme = call_602277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602277.url(scheme.get, call_602277.host, call_602277.base,
                         call_602277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602277, url, valid)

proc call*(call_602278: Call_DeleteDistribution20181105_602265; Id: string): Recallable =
  ## deleteDistribution20181105
  ## Delete a distribution. 
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_602279 = newJObject()
  add(path_602279, "Id", newJString(Id))
  result = call_602278.call(path_602279, nil, nil, nil, nil)

var deleteDistribution20181105* = Call_DeleteDistribution20181105_602265(
    name: "deleteDistribution20181105", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/distribution/{Id}",
    validator: validate_DeleteDistribution20181105_602266, base: "/",
    url: url_DeleteDistribution20181105_602267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryption20181105_602280 = ref object of OpenApiRestCall_601389
proc url_GetFieldLevelEncryption20181105_602282(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-11-05/field-level-encryption/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFieldLevelEncryption20181105_602281(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the field-level encryption configuration information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID for the field-level encryption configuration information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602283 = path.getOrDefault("Id")
  valid_602283 = validateParameter(valid_602283, JString, required = true,
                                 default = nil)
  if valid_602283 != nil:
    section.add "Id", valid_602283
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
  var valid_602284 = header.getOrDefault("X-Amz-Signature")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Signature", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Content-Sha256", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Date")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Date", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Credential")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Credential", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Security-Token")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Security-Token", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-Algorithm")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-Algorithm", valid_602289
  var valid_602290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-SignedHeaders", valid_602290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602291: Call_GetFieldLevelEncryption20181105_602280;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the field-level encryption configuration information.
  ## 
  let valid = call_602291.validator(path, query, header, formData, body)
  let scheme = call_602291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602291.url(scheme.get, call_602291.host, call_602291.base,
                         call_602291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602291, url, valid)

proc call*(call_602292: Call_GetFieldLevelEncryption20181105_602280; Id: string): Recallable =
  ## getFieldLevelEncryption20181105
  ## Get the field-level encryption configuration information.
  ##   Id: string (required)
  ##     : Request the ID for the field-level encryption configuration information.
  var path_602293 = newJObject()
  add(path_602293, "Id", newJString(Id))
  result = call_602292.call(path_602293, nil, nil, nil, nil)

var getFieldLevelEncryption20181105* = Call_GetFieldLevelEncryption20181105_602280(
    name: "getFieldLevelEncryption20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption/{Id}",
    validator: validate_GetFieldLevelEncryption20181105_602281, base: "/",
    url: url_GetFieldLevelEncryption20181105_602282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFieldLevelEncryptionConfig20181105_602294 = ref object of OpenApiRestCall_601389
proc url_DeleteFieldLevelEncryptionConfig20181105_602296(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-11-05/field-level-encryption/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFieldLevelEncryptionConfig20181105_602295(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove a field-level encryption configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the configuration you want to delete from CloudFront.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602297 = path.getOrDefault("Id")
  valid_602297 = validateParameter(valid_602297, JString, required = true,
                                 default = nil)
  if valid_602297 != nil:
    section.add "Id", valid_602297
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the configuration identity to delete. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602298 = header.getOrDefault("X-Amz-Signature")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-Signature", valid_602298
  var valid_602299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-Content-Sha256", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-Date")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Date", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Credential")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Credential", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Security-Token")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Security-Token", valid_602302
  var valid_602303 = header.getOrDefault("If-Match")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "If-Match", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-Algorithm")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-Algorithm", valid_602304
  var valid_602305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-SignedHeaders", valid_602305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602306: Call_DeleteFieldLevelEncryptionConfig20181105_602294;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Remove a field-level encryption configuration.
  ## 
  let valid = call_602306.validator(path, query, header, formData, body)
  let scheme = call_602306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602306.url(scheme.get, call_602306.host, call_602306.base,
                         call_602306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602306, url, valid)

proc call*(call_602307: Call_DeleteFieldLevelEncryptionConfig20181105_602294;
          Id: string): Recallable =
  ## deleteFieldLevelEncryptionConfig20181105
  ## Remove a field-level encryption configuration.
  ##   Id: string (required)
  ##     : The ID of the configuration you want to delete from CloudFront.
  var path_602308 = newJObject()
  add(path_602308, "Id", newJString(Id))
  result = call_602307.call(path_602308, nil, nil, nil, nil)

var deleteFieldLevelEncryptionConfig20181105* = Call_DeleteFieldLevelEncryptionConfig20181105_602294(
    name: "deleteFieldLevelEncryptionConfig20181105", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption/{Id}",
    validator: validate_DeleteFieldLevelEncryptionConfig20181105_602295,
    base: "/", url: url_DeleteFieldLevelEncryptionConfig20181105_602296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryptionProfile20181105_602309 = ref object of OpenApiRestCall_601389
proc url_GetFieldLevelEncryptionProfile20181105_602311(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-11-05/field-level-encryption-profile/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFieldLevelEncryptionProfile20181105_602310(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the field-level encryption profile information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Get the ID for the field-level encryption profile information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602312 = path.getOrDefault("Id")
  valid_602312 = validateParameter(valid_602312, JString, required = true,
                                 default = nil)
  if valid_602312 != nil:
    section.add "Id", valid_602312
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
  var valid_602313 = header.getOrDefault("X-Amz-Signature")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Signature", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Content-Sha256", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Date")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Date", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Credential")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Credential", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Security-Token")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Security-Token", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Algorithm")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Algorithm", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-SignedHeaders", valid_602319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602320: Call_GetFieldLevelEncryptionProfile20181105_602309;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the field-level encryption profile information.
  ## 
  let valid = call_602320.validator(path, query, header, formData, body)
  let scheme = call_602320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602320.url(scheme.get, call_602320.host, call_602320.base,
                         call_602320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602320, url, valid)

proc call*(call_602321: Call_GetFieldLevelEncryptionProfile20181105_602309;
          Id: string): Recallable =
  ## getFieldLevelEncryptionProfile20181105
  ## Get the field-level encryption profile information.
  ##   Id: string (required)
  ##     : Get the ID for the field-level encryption profile information.
  var path_602322 = newJObject()
  add(path_602322, "Id", newJString(Id))
  result = call_602321.call(path_602322, nil, nil, nil, nil)

var getFieldLevelEncryptionProfile20181105* = Call_GetFieldLevelEncryptionProfile20181105_602309(
    name: "getFieldLevelEncryptionProfile20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption-profile/{Id}",
    validator: validate_GetFieldLevelEncryptionProfile20181105_602310, base: "/",
    url: url_GetFieldLevelEncryptionProfile20181105_602311,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFieldLevelEncryptionProfile20181105_602323 = ref object of OpenApiRestCall_601389
proc url_DeleteFieldLevelEncryptionProfile20181105_602325(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-11-05/field-level-encryption-profile/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFieldLevelEncryptionProfile20181105_602324(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove a field-level encryption profile.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID of the profile you want to delete from CloudFront.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602326 = path.getOrDefault("Id")
  valid_602326 = validateParameter(valid_602326, JString, required = true,
                                 default = nil)
  if valid_602326 != nil:
    section.add "Id", valid_602326
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the profile to delete. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602327 = header.getOrDefault("X-Amz-Signature")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-Signature", valid_602327
  var valid_602328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-Content-Sha256", valid_602328
  var valid_602329 = header.getOrDefault("X-Amz-Date")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "X-Amz-Date", valid_602329
  var valid_602330 = header.getOrDefault("X-Amz-Credential")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Credential", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Security-Token")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Security-Token", valid_602331
  var valid_602332 = header.getOrDefault("If-Match")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "If-Match", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Algorithm")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Algorithm", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-SignedHeaders", valid_602334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602335: Call_DeleteFieldLevelEncryptionProfile20181105_602323;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Remove a field-level encryption profile.
  ## 
  let valid = call_602335.validator(path, query, header, formData, body)
  let scheme = call_602335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602335.url(scheme.get, call_602335.host, call_602335.base,
                         call_602335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602335, url, valid)

proc call*(call_602336: Call_DeleteFieldLevelEncryptionProfile20181105_602323;
          Id: string): Recallable =
  ## deleteFieldLevelEncryptionProfile20181105
  ## Remove a field-level encryption profile.
  ##   Id: string (required)
  ##     : Request the ID of the profile you want to delete from CloudFront.
  var path_602337 = newJObject()
  add(path_602337, "Id", newJString(Id))
  result = call_602336.call(path_602337, nil, nil, nil, nil)

var deleteFieldLevelEncryptionProfile20181105* = Call_DeleteFieldLevelEncryptionProfile20181105_602323(
    name: "deleteFieldLevelEncryptionProfile20181105",
    meth: HttpMethod.HttpDelete, host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption-profile/{Id}",
    validator: validate_DeleteFieldLevelEncryptionProfile20181105_602324,
    base: "/", url: url_DeleteFieldLevelEncryptionProfile20181105_602325,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicKey20181105_602338 = ref object of OpenApiRestCall_601389
proc url_GetPublicKey20181105_602340(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/public-key/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPublicKey20181105_602339(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the public key information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID for the public key.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602341 = path.getOrDefault("Id")
  valid_602341 = validateParameter(valid_602341, JString, required = true,
                                 default = nil)
  if valid_602341 != nil:
    section.add "Id", valid_602341
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
  var valid_602342 = header.getOrDefault("X-Amz-Signature")
  valid_602342 = validateParameter(valid_602342, JString, required = false,
                                 default = nil)
  if valid_602342 != nil:
    section.add "X-Amz-Signature", valid_602342
  var valid_602343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602343 = validateParameter(valid_602343, JString, required = false,
                                 default = nil)
  if valid_602343 != nil:
    section.add "X-Amz-Content-Sha256", valid_602343
  var valid_602344 = header.getOrDefault("X-Amz-Date")
  valid_602344 = validateParameter(valid_602344, JString, required = false,
                                 default = nil)
  if valid_602344 != nil:
    section.add "X-Amz-Date", valid_602344
  var valid_602345 = header.getOrDefault("X-Amz-Credential")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "X-Amz-Credential", valid_602345
  var valid_602346 = header.getOrDefault("X-Amz-Security-Token")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-Security-Token", valid_602346
  var valid_602347 = header.getOrDefault("X-Amz-Algorithm")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Algorithm", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-SignedHeaders", valid_602348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602349: Call_GetPublicKey20181105_602338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the public key information.
  ## 
  let valid = call_602349.validator(path, query, header, formData, body)
  let scheme = call_602349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602349.url(scheme.get, call_602349.host, call_602349.base,
                         call_602349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602349, url, valid)

proc call*(call_602350: Call_GetPublicKey20181105_602338; Id: string): Recallable =
  ## getPublicKey20181105
  ## Get the public key information.
  ##   Id: string (required)
  ##     : Request the ID for the public key.
  var path_602351 = newJObject()
  add(path_602351, "Id", newJString(Id))
  result = call_602350.call(path_602351, nil, nil, nil, nil)

var getPublicKey20181105* = Call_GetPublicKey20181105_602338(
    name: "getPublicKey20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/public-key/{Id}",
    validator: validate_GetPublicKey20181105_602339, base: "/",
    url: url_GetPublicKey20181105_602340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicKey20181105_602352 = ref object of OpenApiRestCall_601389
proc url_DeletePublicKey20181105_602354(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/public-key/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePublicKey20181105_602353(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove a public key you previously added to CloudFront.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the public key you want to remove from CloudFront.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602355 = path.getOrDefault("Id")
  valid_602355 = validateParameter(valid_602355, JString, required = true,
                                 default = nil)
  if valid_602355 != nil:
    section.add "Id", valid_602355
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the public key identity to delete. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602356 = header.getOrDefault("X-Amz-Signature")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-Signature", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Content-Sha256", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-Date")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-Date", valid_602358
  var valid_602359 = header.getOrDefault("X-Amz-Credential")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Credential", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-Security-Token")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-Security-Token", valid_602360
  var valid_602361 = header.getOrDefault("If-Match")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "If-Match", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-Algorithm")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Algorithm", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-SignedHeaders", valid_602363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602364: Call_DeletePublicKey20181105_602352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove a public key you previously added to CloudFront.
  ## 
  let valid = call_602364.validator(path, query, header, formData, body)
  let scheme = call_602364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602364.url(scheme.get, call_602364.host, call_602364.base,
                         call_602364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602364, url, valid)

proc call*(call_602365: Call_DeletePublicKey20181105_602352; Id: string): Recallable =
  ## deletePublicKey20181105
  ## Remove a public key you previously added to CloudFront.
  ##   Id: string (required)
  ##     : The ID of the public key you want to remove from CloudFront.
  var path_602366 = newJObject()
  add(path_602366, "Id", newJString(Id))
  result = call_602365.call(path_602366, nil, nil, nil, nil)

var deletePublicKey20181105* = Call_DeletePublicKey20181105_602352(
    name: "deletePublicKey20181105", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/public-key/{Id}",
    validator: validate_DeletePublicKey20181105_602353, base: "/",
    url: url_DeletePublicKey20181105_602354, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistribution20181105_602367 = ref object of OpenApiRestCall_601389
proc url_GetStreamingDistribution20181105_602369(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-11-05/streaming-distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStreamingDistribution20181105_602368(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602370 = path.getOrDefault("Id")
  valid_602370 = validateParameter(valid_602370, JString, required = true,
                                 default = nil)
  if valid_602370 != nil:
    section.add "Id", valid_602370
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
  var valid_602371 = header.getOrDefault("X-Amz-Signature")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-Signature", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-Content-Sha256", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-Date")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-Date", valid_602373
  var valid_602374 = header.getOrDefault("X-Amz-Credential")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "X-Amz-Credential", valid_602374
  var valid_602375 = header.getOrDefault("X-Amz-Security-Token")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "X-Amz-Security-Token", valid_602375
  var valid_602376 = header.getOrDefault("X-Amz-Algorithm")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-Algorithm", valid_602376
  var valid_602377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-SignedHeaders", valid_602377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602378: Call_GetStreamingDistribution20181105_602367;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ## 
  let valid = call_602378.validator(path, query, header, formData, body)
  let scheme = call_602378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602378.url(scheme.get, call_602378.host, call_602378.base,
                         call_602378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602378, url, valid)

proc call*(call_602379: Call_GetStreamingDistribution20181105_602367; Id: string): Recallable =
  ## getStreamingDistribution20181105
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_602380 = newJObject()
  add(path_602380, "Id", newJString(Id))
  result = call_602379.call(path_602380, nil, nil, nil, nil)

var getStreamingDistribution20181105* = Call_GetStreamingDistribution20181105_602367(
    name: "getStreamingDistribution20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/streaming-distribution/{Id}",
    validator: validate_GetStreamingDistribution20181105_602368, base: "/",
    url: url_GetStreamingDistribution20181105_602369,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStreamingDistribution20181105_602381 = ref object of OpenApiRestCall_601389
proc url_DeleteStreamingDistribution20181105_602383(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-11-05/streaming-distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteStreamingDistribution20181105_602382(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602384 = path.getOrDefault("Id")
  valid_602384 = validateParameter(valid_602384, JString, required = true,
                                 default = nil)
  if valid_602384 != nil:
    section.add "Id", valid_602384
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when you disabled the streaming distribution. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602385 = header.getOrDefault("X-Amz-Signature")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-Signature", valid_602385
  var valid_602386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "X-Amz-Content-Sha256", valid_602386
  var valid_602387 = header.getOrDefault("X-Amz-Date")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-Date", valid_602387
  var valid_602388 = header.getOrDefault("X-Amz-Credential")
  valid_602388 = validateParameter(valid_602388, JString, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "X-Amz-Credential", valid_602388
  var valid_602389 = header.getOrDefault("X-Amz-Security-Token")
  valid_602389 = validateParameter(valid_602389, JString, required = false,
                                 default = nil)
  if valid_602389 != nil:
    section.add "X-Amz-Security-Token", valid_602389
  var valid_602390 = header.getOrDefault("If-Match")
  valid_602390 = validateParameter(valid_602390, JString, required = false,
                                 default = nil)
  if valid_602390 != nil:
    section.add "If-Match", valid_602390
  var valid_602391 = header.getOrDefault("X-Amz-Algorithm")
  valid_602391 = validateParameter(valid_602391, JString, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "X-Amz-Algorithm", valid_602391
  var valid_602392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "X-Amz-SignedHeaders", valid_602392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602393: Call_DeleteStreamingDistribution20181105_602381;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ## 
  let valid = call_602393.validator(path, query, header, formData, body)
  let scheme = call_602393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602393.url(scheme.get, call_602393.host, call_602393.base,
                         call_602393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602393, url, valid)

proc call*(call_602394: Call_DeleteStreamingDistribution20181105_602381; Id: string): Recallable =
  ## deleteStreamingDistribution20181105
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_602395 = newJObject()
  add(path_602395, "Id", newJString(Id))
  result = call_602394.call(path_602395, nil, nil, nil, nil)

var deleteStreamingDistribution20181105* = Call_DeleteStreamingDistribution20181105_602381(
    name: "deleteStreamingDistribution20181105", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/streaming-distribution/{Id}",
    validator: validate_DeleteStreamingDistribution20181105_602382, base: "/",
    url: url_DeleteStreamingDistribution20181105_602383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCloudFrontOriginAccessIdentity20181105_602410 = ref object of OpenApiRestCall_601389
proc url_UpdateCloudFrontOriginAccessIdentity20181105_602412(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-11-05/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateCloudFrontOriginAccessIdentity20181105_602411(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602413 = path.getOrDefault("Id")
  valid_602413 = validateParameter(valid_602413, JString, required = true,
                                 default = nil)
  if valid_602413 != nil:
    section.add "Id", valid_602413
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the identity's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602414 = header.getOrDefault("X-Amz-Signature")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Signature", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Content-Sha256", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-Date")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Date", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-Credential")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Credential", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-Security-Token")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-Security-Token", valid_602418
  var valid_602419 = header.getOrDefault("If-Match")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "If-Match", valid_602419
  var valid_602420 = header.getOrDefault("X-Amz-Algorithm")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-Algorithm", valid_602420
  var valid_602421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "X-Amz-SignedHeaders", valid_602421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602423: Call_UpdateCloudFrontOriginAccessIdentity20181105_602410;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update an origin access identity. 
  ## 
  let valid = call_602423.validator(path, query, header, formData, body)
  let scheme = call_602423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602423.url(scheme.get, call_602423.host, call_602423.base,
                         call_602423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602423, url, valid)

proc call*(call_602424: Call_UpdateCloudFrontOriginAccessIdentity20181105_602410;
          body: JsonNode; Id: string): Recallable =
  ## updateCloudFrontOriginAccessIdentity20181105
  ## Update an origin access identity. 
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The identity's id.
  var path_602425 = newJObject()
  var body_602426 = newJObject()
  if body != nil:
    body_602426 = body
  add(path_602425, "Id", newJString(Id))
  result = call_602424.call(path_602425, nil, nil, nil, body_602426)

var updateCloudFrontOriginAccessIdentity20181105* = Call_UpdateCloudFrontOriginAccessIdentity20181105_602410(
    name: "updateCloudFrontOriginAccessIdentity20181105",
    meth: HttpMethod.HttpPut, host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_UpdateCloudFrontOriginAccessIdentity20181105_602411,
    base: "/", url: url_UpdateCloudFrontOriginAccessIdentity20181105_602412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentityConfig20181105_602396 = ref object of OpenApiRestCall_601389
proc url_GetCloudFrontOriginAccessIdentityConfig20181105_602398(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-11-05/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCloudFrontOriginAccessIdentityConfig20181105_602397(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Get the configuration information about an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602399 = path.getOrDefault("Id")
  valid_602399 = validateParameter(valid_602399, JString, required = true,
                                 default = nil)
  if valid_602399 != nil:
    section.add "Id", valid_602399
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
  var valid_602400 = header.getOrDefault("X-Amz-Signature")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-Signature", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Content-Sha256", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-Date")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Date", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-Credential")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-Credential", valid_602403
  var valid_602404 = header.getOrDefault("X-Amz-Security-Token")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "X-Amz-Security-Token", valid_602404
  var valid_602405 = header.getOrDefault("X-Amz-Algorithm")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "X-Amz-Algorithm", valid_602405
  var valid_602406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-SignedHeaders", valid_602406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602407: Call_GetCloudFrontOriginAccessIdentityConfig20181105_602396;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the configuration information about an origin access identity. 
  ## 
  let valid = call_602407.validator(path, query, header, formData, body)
  let scheme = call_602407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602407.url(scheme.get, call_602407.host, call_602407.base,
                         call_602407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602407, url, valid)

proc call*(call_602408: Call_GetCloudFrontOriginAccessIdentityConfig20181105_602396;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentityConfig20181105
  ## Get the configuration information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID. 
  var path_602409 = newJObject()
  add(path_602409, "Id", newJString(Id))
  result = call_602408.call(path_602409, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentityConfig20181105* = Call_GetCloudFrontOriginAccessIdentityConfig20181105_602396(
    name: "getCloudFrontOriginAccessIdentityConfig20181105",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_GetCloudFrontOriginAccessIdentityConfig20181105_602397,
    base: "/", url: url_GetCloudFrontOriginAccessIdentityConfig20181105_602398,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDistribution20181105_602441 = ref object of OpenApiRestCall_601389
proc url_UpdateDistribution20181105_602443(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDistribution20181105_602442(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the configuration for a web distribution. </p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using this API action, follow the steps here to get the current configuration and then make your updates, to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>The update process includes getting the current distribution configuration, updating the XML document that is returned to make your changes, and then submitting an <code>UpdateDistribution</code> request to make the updates.</p> <p>For information about updating a distribution using the CloudFront console instead, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a>GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you must get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include your changes. </p> <important> <p>When you edit the XML file, be aware of the following:</p> <ul> <li> <p>You must strip out the ETag parameter that is returned.</p> </li> <li> <p>Additional fields are required when you update a distribution. There may be fields included in the XML file for features that you haven't configured for your distribution. This is expected and required to successfully update the distribution.</p> </li> <li> <p>You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error. </p> </li> <li> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into your existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </li> </ul> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a>GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> </ol>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602444 = path.getOrDefault("Id")
  valid_602444 = validateParameter(valid_602444, JString, required = true,
                                 default = nil)
  if valid_602444 != nil:
    section.add "Id", valid_602444
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602445 = header.getOrDefault("X-Amz-Signature")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-Signature", valid_602445
  var valid_602446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "X-Amz-Content-Sha256", valid_602446
  var valid_602447 = header.getOrDefault("X-Amz-Date")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-Date", valid_602447
  var valid_602448 = header.getOrDefault("X-Amz-Credential")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-Credential", valid_602448
  var valid_602449 = header.getOrDefault("X-Amz-Security-Token")
  valid_602449 = validateParameter(valid_602449, JString, required = false,
                                 default = nil)
  if valid_602449 != nil:
    section.add "X-Amz-Security-Token", valid_602449
  var valid_602450 = header.getOrDefault("If-Match")
  valid_602450 = validateParameter(valid_602450, JString, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "If-Match", valid_602450
  var valid_602451 = header.getOrDefault("X-Amz-Algorithm")
  valid_602451 = validateParameter(valid_602451, JString, required = false,
                                 default = nil)
  if valid_602451 != nil:
    section.add "X-Amz-Algorithm", valid_602451
  var valid_602452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "X-Amz-SignedHeaders", valid_602452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602454: Call_UpdateDistribution20181105_602441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the configuration for a web distribution. </p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using this API action, follow the steps here to get the current configuration and then make your updates, to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>The update process includes getting the current distribution configuration, updating the XML document that is returned to make your changes, and then submitting an <code>UpdateDistribution</code> request to make the updates.</p> <p>For information about updating a distribution using the CloudFront console instead, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a>GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you must get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include your changes. </p> <important> <p>When you edit the XML file, be aware of the following:</p> <ul> <li> <p>You must strip out the ETag parameter that is returned.</p> </li> <li> <p>Additional fields are required when you update a distribution. There may be fields included in the XML file for features that you haven't configured for your distribution. This is expected and required to successfully update the distribution.</p> </li> <li> <p>You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error. </p> </li> <li> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into your existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </li> </ul> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a>GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> </ol>
  ## 
  let valid = call_602454.validator(path, query, header, formData, body)
  let scheme = call_602454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602454.url(scheme.get, call_602454.host, call_602454.base,
                         call_602454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602454, url, valid)

proc call*(call_602455: Call_UpdateDistribution20181105_602441; body: JsonNode;
          Id: string): Recallable =
  ## updateDistribution20181105
  ## <p>Updates the configuration for a web distribution. </p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using this API action, follow the steps here to get the current configuration and then make your updates, to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>The update process includes getting the current distribution configuration, updating the XML document that is returned to make your changes, and then submitting an <code>UpdateDistribution</code> request to make the updates.</p> <p>For information about updating a distribution using the CloudFront console instead, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a>GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you must get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include your changes. </p> <important> <p>When you edit the XML file, be aware of the following:</p> <ul> <li> <p>You must strip out the ETag parameter that is returned.</p> </li> <li> <p>Additional fields are required when you update a distribution. There may be fields included in the XML file for features that you haven't configured for your distribution. This is expected and required to successfully update the distribution.</p> </li> <li> <p>You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error. </p> </li> <li> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into your existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </li> </ul> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a>GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> </ol>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The distribution's id.
  var path_602456 = newJObject()
  var body_602457 = newJObject()
  if body != nil:
    body_602457 = body
  add(path_602456, "Id", newJString(Id))
  result = call_602455.call(path_602456, nil, nil, nil, body_602457)

var updateDistribution20181105* = Call_UpdateDistribution20181105_602441(
    name: "updateDistribution20181105", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/distribution/{Id}/config",
    validator: validate_UpdateDistribution20181105_602442, base: "/",
    url: url_UpdateDistribution20181105_602443,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistributionConfig20181105_602427 = ref object of OpenApiRestCall_601389
proc url_GetDistributionConfig20181105_602429(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDistributionConfig20181105_602428(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the configuration information about a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602430 = path.getOrDefault("Id")
  valid_602430 = validateParameter(valid_602430, JString, required = true,
                                 default = nil)
  if valid_602430 != nil:
    section.add "Id", valid_602430
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
  var valid_602431 = header.getOrDefault("X-Amz-Signature")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "X-Amz-Signature", valid_602431
  var valid_602432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "X-Amz-Content-Sha256", valid_602432
  var valid_602433 = header.getOrDefault("X-Amz-Date")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-Date", valid_602433
  var valid_602434 = header.getOrDefault("X-Amz-Credential")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "X-Amz-Credential", valid_602434
  var valid_602435 = header.getOrDefault("X-Amz-Security-Token")
  valid_602435 = validateParameter(valid_602435, JString, required = false,
                                 default = nil)
  if valid_602435 != nil:
    section.add "X-Amz-Security-Token", valid_602435
  var valid_602436 = header.getOrDefault("X-Amz-Algorithm")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "X-Amz-Algorithm", valid_602436
  var valid_602437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "X-Amz-SignedHeaders", valid_602437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602438: Call_GetDistributionConfig20181105_602427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the configuration information about a distribution. 
  ## 
  let valid = call_602438.validator(path, query, header, formData, body)
  let scheme = call_602438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602438.url(scheme.get, call_602438.host, call_602438.base,
                         call_602438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602438, url, valid)

proc call*(call_602439: Call_GetDistributionConfig20181105_602427; Id: string): Recallable =
  ## getDistributionConfig20181105
  ## Get the configuration information about a distribution. 
  ##   Id: string (required)
  ##     : The distribution's ID.
  var path_602440 = newJObject()
  add(path_602440, "Id", newJString(Id))
  result = call_602439.call(path_602440, nil, nil, nil, nil)

var getDistributionConfig20181105* = Call_GetDistributionConfig20181105_602427(
    name: "getDistributionConfig20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/distribution/{Id}/config",
    validator: validate_GetDistributionConfig20181105_602428, base: "/",
    url: url_GetDistributionConfig20181105_602429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFieldLevelEncryptionConfig20181105_602472 = ref object of OpenApiRestCall_601389
proc url_UpdateFieldLevelEncryptionConfig20181105_602474(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-11-05/field-level-encryption/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFieldLevelEncryptionConfig20181105_602473(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update a field-level encryption configuration. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the configuration you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602475 = path.getOrDefault("Id")
  valid_602475 = validateParameter(valid_602475, JString, required = true,
                                 default = nil)
  if valid_602475 != nil:
    section.add "Id", valid_602475
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the configuration identity to update. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602476 = header.getOrDefault("X-Amz-Signature")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-Signature", valid_602476
  var valid_602477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-Content-Sha256", valid_602477
  var valid_602478 = header.getOrDefault("X-Amz-Date")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "X-Amz-Date", valid_602478
  var valid_602479 = header.getOrDefault("X-Amz-Credential")
  valid_602479 = validateParameter(valid_602479, JString, required = false,
                                 default = nil)
  if valid_602479 != nil:
    section.add "X-Amz-Credential", valid_602479
  var valid_602480 = header.getOrDefault("X-Amz-Security-Token")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "X-Amz-Security-Token", valid_602480
  var valid_602481 = header.getOrDefault("If-Match")
  valid_602481 = validateParameter(valid_602481, JString, required = false,
                                 default = nil)
  if valid_602481 != nil:
    section.add "If-Match", valid_602481
  var valid_602482 = header.getOrDefault("X-Amz-Algorithm")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "X-Amz-Algorithm", valid_602482
  var valid_602483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602483 = validateParameter(valid_602483, JString, required = false,
                                 default = nil)
  if valid_602483 != nil:
    section.add "X-Amz-SignedHeaders", valid_602483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602485: Call_UpdateFieldLevelEncryptionConfig20181105_602472;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update a field-level encryption configuration. 
  ## 
  let valid = call_602485.validator(path, query, header, formData, body)
  let scheme = call_602485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602485.url(scheme.get, call_602485.host, call_602485.base,
                         call_602485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602485, url, valid)

proc call*(call_602486: Call_UpdateFieldLevelEncryptionConfig20181105_602472;
          body: JsonNode; Id: string): Recallable =
  ## updateFieldLevelEncryptionConfig20181105
  ## Update a field-level encryption configuration. 
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the configuration you want to update.
  var path_602487 = newJObject()
  var body_602488 = newJObject()
  if body != nil:
    body_602488 = body
  add(path_602487, "Id", newJString(Id))
  result = call_602486.call(path_602487, nil, nil, nil, body_602488)

var updateFieldLevelEncryptionConfig20181105* = Call_UpdateFieldLevelEncryptionConfig20181105_602472(
    name: "updateFieldLevelEncryptionConfig20181105", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption/{Id}/config",
    validator: validate_UpdateFieldLevelEncryptionConfig20181105_602473,
    base: "/", url: url_UpdateFieldLevelEncryptionConfig20181105_602474,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryptionConfig20181105_602458 = ref object of OpenApiRestCall_601389
proc url_GetFieldLevelEncryptionConfig20181105_602460(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-11-05/field-level-encryption/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFieldLevelEncryptionConfig20181105_602459(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the field-level encryption configuration information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID for the field-level encryption configuration information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602461 = path.getOrDefault("Id")
  valid_602461 = validateParameter(valid_602461, JString, required = true,
                                 default = nil)
  if valid_602461 != nil:
    section.add "Id", valid_602461
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
  var valid_602462 = header.getOrDefault("X-Amz-Signature")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-Signature", valid_602462
  var valid_602463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602463 = validateParameter(valid_602463, JString, required = false,
                                 default = nil)
  if valid_602463 != nil:
    section.add "X-Amz-Content-Sha256", valid_602463
  var valid_602464 = header.getOrDefault("X-Amz-Date")
  valid_602464 = validateParameter(valid_602464, JString, required = false,
                                 default = nil)
  if valid_602464 != nil:
    section.add "X-Amz-Date", valid_602464
  var valid_602465 = header.getOrDefault("X-Amz-Credential")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-Credential", valid_602465
  var valid_602466 = header.getOrDefault("X-Amz-Security-Token")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "X-Amz-Security-Token", valid_602466
  var valid_602467 = header.getOrDefault("X-Amz-Algorithm")
  valid_602467 = validateParameter(valid_602467, JString, required = false,
                                 default = nil)
  if valid_602467 != nil:
    section.add "X-Amz-Algorithm", valid_602467
  var valid_602468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "X-Amz-SignedHeaders", valid_602468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602469: Call_GetFieldLevelEncryptionConfig20181105_602458;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the field-level encryption configuration information.
  ## 
  let valid = call_602469.validator(path, query, header, formData, body)
  let scheme = call_602469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602469.url(scheme.get, call_602469.host, call_602469.base,
                         call_602469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602469, url, valid)

proc call*(call_602470: Call_GetFieldLevelEncryptionConfig20181105_602458;
          Id: string): Recallable =
  ## getFieldLevelEncryptionConfig20181105
  ## Get the field-level encryption configuration information.
  ##   Id: string (required)
  ##     : Request the ID for the field-level encryption configuration information.
  var path_602471 = newJObject()
  add(path_602471, "Id", newJString(Id))
  result = call_602470.call(path_602471, nil, nil, nil, nil)

var getFieldLevelEncryptionConfig20181105* = Call_GetFieldLevelEncryptionConfig20181105_602458(
    name: "getFieldLevelEncryptionConfig20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption/{Id}/config",
    validator: validate_GetFieldLevelEncryptionConfig20181105_602459, base: "/",
    url: url_GetFieldLevelEncryptionConfig20181105_602460,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFieldLevelEncryptionProfile20181105_602503 = ref object of OpenApiRestCall_601389
proc url_UpdateFieldLevelEncryptionProfile20181105_602505(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-11-05/field-level-encryption-profile/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFieldLevelEncryptionProfile20181105_602504(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update a field-level encryption profile. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the field-level encryption profile request. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602506 = path.getOrDefault("Id")
  valid_602506 = validateParameter(valid_602506, JString, required = true,
                                 default = nil)
  if valid_602506 != nil:
    section.add "Id", valid_602506
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the profile identity to update. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602507 = header.getOrDefault("X-Amz-Signature")
  valid_602507 = validateParameter(valid_602507, JString, required = false,
                                 default = nil)
  if valid_602507 != nil:
    section.add "X-Amz-Signature", valid_602507
  var valid_602508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "X-Amz-Content-Sha256", valid_602508
  var valid_602509 = header.getOrDefault("X-Amz-Date")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-Date", valid_602509
  var valid_602510 = header.getOrDefault("X-Amz-Credential")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-Credential", valid_602510
  var valid_602511 = header.getOrDefault("X-Amz-Security-Token")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "X-Amz-Security-Token", valid_602511
  var valid_602512 = header.getOrDefault("If-Match")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "If-Match", valid_602512
  var valid_602513 = header.getOrDefault("X-Amz-Algorithm")
  valid_602513 = validateParameter(valid_602513, JString, required = false,
                                 default = nil)
  if valid_602513 != nil:
    section.add "X-Amz-Algorithm", valid_602513
  var valid_602514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602514 = validateParameter(valid_602514, JString, required = false,
                                 default = nil)
  if valid_602514 != nil:
    section.add "X-Amz-SignedHeaders", valid_602514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602516: Call_UpdateFieldLevelEncryptionProfile20181105_602503;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update a field-level encryption profile. 
  ## 
  let valid = call_602516.validator(path, query, header, formData, body)
  let scheme = call_602516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602516.url(scheme.get, call_602516.host, call_602516.base,
                         call_602516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602516, url, valid)

proc call*(call_602517: Call_UpdateFieldLevelEncryptionProfile20181105_602503;
          body: JsonNode; Id: string): Recallable =
  ## updateFieldLevelEncryptionProfile20181105
  ## Update a field-level encryption profile. 
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the field-level encryption profile request. 
  var path_602518 = newJObject()
  var body_602519 = newJObject()
  if body != nil:
    body_602519 = body
  add(path_602518, "Id", newJString(Id))
  result = call_602517.call(path_602518, nil, nil, nil, body_602519)

var updateFieldLevelEncryptionProfile20181105* = Call_UpdateFieldLevelEncryptionProfile20181105_602503(
    name: "updateFieldLevelEncryptionProfile20181105", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption-profile/{Id}/config",
    validator: validate_UpdateFieldLevelEncryptionProfile20181105_602504,
    base: "/", url: url_UpdateFieldLevelEncryptionProfile20181105_602505,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryptionProfileConfig20181105_602489 = ref object of OpenApiRestCall_601389
proc url_GetFieldLevelEncryptionProfileConfig20181105_602491(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-11-05/field-level-encryption-profile/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFieldLevelEncryptionProfileConfig20181105_602490(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the field-level encryption profile configuration information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Get the ID for the field-level encryption profile configuration information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602492 = path.getOrDefault("Id")
  valid_602492 = validateParameter(valid_602492, JString, required = true,
                                 default = nil)
  if valid_602492 != nil:
    section.add "Id", valid_602492
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
  var valid_602493 = header.getOrDefault("X-Amz-Signature")
  valid_602493 = validateParameter(valid_602493, JString, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "X-Amz-Signature", valid_602493
  var valid_602494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602494 = validateParameter(valid_602494, JString, required = false,
                                 default = nil)
  if valid_602494 != nil:
    section.add "X-Amz-Content-Sha256", valid_602494
  var valid_602495 = header.getOrDefault("X-Amz-Date")
  valid_602495 = validateParameter(valid_602495, JString, required = false,
                                 default = nil)
  if valid_602495 != nil:
    section.add "X-Amz-Date", valid_602495
  var valid_602496 = header.getOrDefault("X-Amz-Credential")
  valid_602496 = validateParameter(valid_602496, JString, required = false,
                                 default = nil)
  if valid_602496 != nil:
    section.add "X-Amz-Credential", valid_602496
  var valid_602497 = header.getOrDefault("X-Amz-Security-Token")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "X-Amz-Security-Token", valid_602497
  var valid_602498 = header.getOrDefault("X-Amz-Algorithm")
  valid_602498 = validateParameter(valid_602498, JString, required = false,
                                 default = nil)
  if valid_602498 != nil:
    section.add "X-Amz-Algorithm", valid_602498
  var valid_602499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "X-Amz-SignedHeaders", valid_602499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602500: Call_GetFieldLevelEncryptionProfileConfig20181105_602489;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the field-level encryption profile configuration information.
  ## 
  let valid = call_602500.validator(path, query, header, formData, body)
  let scheme = call_602500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602500.url(scheme.get, call_602500.host, call_602500.base,
                         call_602500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602500, url, valid)

proc call*(call_602501: Call_GetFieldLevelEncryptionProfileConfig20181105_602489;
          Id: string): Recallable =
  ## getFieldLevelEncryptionProfileConfig20181105
  ## Get the field-level encryption profile configuration information.
  ##   Id: string (required)
  ##     : Get the ID for the field-level encryption profile configuration information.
  var path_602502 = newJObject()
  add(path_602502, "Id", newJString(Id))
  result = call_602501.call(path_602502, nil, nil, nil, nil)

var getFieldLevelEncryptionProfileConfig20181105* = Call_GetFieldLevelEncryptionProfileConfig20181105_602489(
    name: "getFieldLevelEncryptionProfileConfig20181105",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption-profile/{Id}/config",
    validator: validate_GetFieldLevelEncryptionProfileConfig20181105_602490,
    base: "/", url: url_GetFieldLevelEncryptionProfileConfig20181105_602491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvalidation20181105_602520 = ref object of OpenApiRestCall_601389
proc url_GetInvalidation20181105_602522(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetInvalidation20181105_602521(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the information about an invalidation. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
  ##                 : The distribution's ID.
  ##   Id: JString (required)
  ##     : The identifier for the invalidation request, for example, <code>IDFDVBD632BHDS5</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DistributionId` field"
  var valid_602523 = path.getOrDefault("DistributionId")
  valid_602523 = validateParameter(valid_602523, JString, required = true,
                                 default = nil)
  if valid_602523 != nil:
    section.add "DistributionId", valid_602523
  var valid_602524 = path.getOrDefault("Id")
  valid_602524 = validateParameter(valid_602524, JString, required = true,
                                 default = nil)
  if valid_602524 != nil:
    section.add "Id", valid_602524
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
  var valid_602525 = header.getOrDefault("X-Amz-Signature")
  valid_602525 = validateParameter(valid_602525, JString, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "X-Amz-Signature", valid_602525
  var valid_602526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602526 = validateParameter(valid_602526, JString, required = false,
                                 default = nil)
  if valid_602526 != nil:
    section.add "X-Amz-Content-Sha256", valid_602526
  var valid_602527 = header.getOrDefault("X-Amz-Date")
  valid_602527 = validateParameter(valid_602527, JString, required = false,
                                 default = nil)
  if valid_602527 != nil:
    section.add "X-Amz-Date", valid_602527
  var valid_602528 = header.getOrDefault("X-Amz-Credential")
  valid_602528 = validateParameter(valid_602528, JString, required = false,
                                 default = nil)
  if valid_602528 != nil:
    section.add "X-Amz-Credential", valid_602528
  var valid_602529 = header.getOrDefault("X-Amz-Security-Token")
  valid_602529 = validateParameter(valid_602529, JString, required = false,
                                 default = nil)
  if valid_602529 != nil:
    section.add "X-Amz-Security-Token", valid_602529
  var valid_602530 = header.getOrDefault("X-Amz-Algorithm")
  valid_602530 = validateParameter(valid_602530, JString, required = false,
                                 default = nil)
  if valid_602530 != nil:
    section.add "X-Amz-Algorithm", valid_602530
  var valid_602531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602531 = validateParameter(valid_602531, JString, required = false,
                                 default = nil)
  if valid_602531 != nil:
    section.add "X-Amz-SignedHeaders", valid_602531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602532: Call_GetInvalidation20181105_602520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the information about an invalidation. 
  ## 
  let valid = call_602532.validator(path, query, header, formData, body)
  let scheme = call_602532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602532.url(scheme.get, call_602532.host, call_602532.base,
                         call_602532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602532, url, valid)

proc call*(call_602533: Call_GetInvalidation20181105_602520;
          DistributionId: string; Id: string): Recallable =
  ## getInvalidation20181105
  ## Get the information about an invalidation. 
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  ##   Id: string (required)
  ##     : The identifier for the invalidation request, for example, <code>IDFDVBD632BHDS5</code>.
  var path_602534 = newJObject()
  add(path_602534, "DistributionId", newJString(DistributionId))
  add(path_602534, "Id", newJString(Id))
  result = call_602533.call(path_602534, nil, nil, nil, nil)

var getInvalidation20181105* = Call_GetInvalidation20181105_602520(
    name: "getInvalidation20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/distribution/{DistributionId}/invalidation/{Id}",
    validator: validate_GetInvalidation20181105_602521, base: "/",
    url: url_GetInvalidation20181105_602522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePublicKey20181105_602549 = ref object of OpenApiRestCall_601389
proc url_UpdatePublicKey20181105_602551(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/public-key/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePublicKey20181105_602550(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update public key information. Note that the only value you can change is the comment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : ID of the public key to be updated.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602552 = path.getOrDefault("Id")
  valid_602552 = validateParameter(valid_602552, JString, required = true,
                                 default = nil)
  if valid_602552 != nil:
    section.add "Id", valid_602552
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the public key to update. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602553 = header.getOrDefault("X-Amz-Signature")
  valid_602553 = validateParameter(valid_602553, JString, required = false,
                                 default = nil)
  if valid_602553 != nil:
    section.add "X-Amz-Signature", valid_602553
  var valid_602554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602554 = validateParameter(valid_602554, JString, required = false,
                                 default = nil)
  if valid_602554 != nil:
    section.add "X-Amz-Content-Sha256", valid_602554
  var valid_602555 = header.getOrDefault("X-Amz-Date")
  valid_602555 = validateParameter(valid_602555, JString, required = false,
                                 default = nil)
  if valid_602555 != nil:
    section.add "X-Amz-Date", valid_602555
  var valid_602556 = header.getOrDefault("X-Amz-Credential")
  valid_602556 = validateParameter(valid_602556, JString, required = false,
                                 default = nil)
  if valid_602556 != nil:
    section.add "X-Amz-Credential", valid_602556
  var valid_602557 = header.getOrDefault("X-Amz-Security-Token")
  valid_602557 = validateParameter(valid_602557, JString, required = false,
                                 default = nil)
  if valid_602557 != nil:
    section.add "X-Amz-Security-Token", valid_602557
  var valid_602558 = header.getOrDefault("If-Match")
  valid_602558 = validateParameter(valid_602558, JString, required = false,
                                 default = nil)
  if valid_602558 != nil:
    section.add "If-Match", valid_602558
  var valid_602559 = header.getOrDefault("X-Amz-Algorithm")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "X-Amz-Algorithm", valid_602559
  var valid_602560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "X-Amz-SignedHeaders", valid_602560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602562: Call_UpdatePublicKey20181105_602549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update public key information. Note that the only value you can change is the comment.
  ## 
  let valid = call_602562.validator(path, query, header, formData, body)
  let scheme = call_602562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602562.url(scheme.get, call_602562.host, call_602562.base,
                         call_602562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602562, url, valid)

proc call*(call_602563: Call_UpdatePublicKey20181105_602549; body: JsonNode;
          Id: string): Recallable =
  ## updatePublicKey20181105
  ## Update public key information. Note that the only value you can change is the comment.
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : ID of the public key to be updated.
  var path_602564 = newJObject()
  var body_602565 = newJObject()
  if body != nil:
    body_602565 = body
  add(path_602564, "Id", newJString(Id))
  result = call_602563.call(path_602564, nil, nil, nil, body_602565)

var updatePublicKey20181105* = Call_UpdatePublicKey20181105_602549(
    name: "updatePublicKey20181105", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/public-key/{Id}/config",
    validator: validate_UpdatePublicKey20181105_602550, base: "/",
    url: url_UpdatePublicKey20181105_602551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicKeyConfig20181105_602535 = ref object of OpenApiRestCall_601389
proc url_GetPublicKeyConfig20181105_602537(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/public-key/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPublicKeyConfig20181105_602536(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Return public key configuration informaation
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID for the public key configuration.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602538 = path.getOrDefault("Id")
  valid_602538 = validateParameter(valid_602538, JString, required = true,
                                 default = nil)
  if valid_602538 != nil:
    section.add "Id", valid_602538
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
  var valid_602539 = header.getOrDefault("X-Amz-Signature")
  valid_602539 = validateParameter(valid_602539, JString, required = false,
                                 default = nil)
  if valid_602539 != nil:
    section.add "X-Amz-Signature", valid_602539
  var valid_602540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602540 = validateParameter(valid_602540, JString, required = false,
                                 default = nil)
  if valid_602540 != nil:
    section.add "X-Amz-Content-Sha256", valid_602540
  var valid_602541 = header.getOrDefault("X-Amz-Date")
  valid_602541 = validateParameter(valid_602541, JString, required = false,
                                 default = nil)
  if valid_602541 != nil:
    section.add "X-Amz-Date", valid_602541
  var valid_602542 = header.getOrDefault("X-Amz-Credential")
  valid_602542 = validateParameter(valid_602542, JString, required = false,
                                 default = nil)
  if valid_602542 != nil:
    section.add "X-Amz-Credential", valid_602542
  var valid_602543 = header.getOrDefault("X-Amz-Security-Token")
  valid_602543 = validateParameter(valid_602543, JString, required = false,
                                 default = nil)
  if valid_602543 != nil:
    section.add "X-Amz-Security-Token", valid_602543
  var valid_602544 = header.getOrDefault("X-Amz-Algorithm")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-Algorithm", valid_602544
  var valid_602545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-SignedHeaders", valid_602545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602546: Call_GetPublicKeyConfig20181105_602535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Return public key configuration informaation
  ## 
  let valid = call_602546.validator(path, query, header, formData, body)
  let scheme = call_602546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602546.url(scheme.get, call_602546.host, call_602546.base,
                         call_602546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602546, url, valid)

proc call*(call_602547: Call_GetPublicKeyConfig20181105_602535; Id: string): Recallable =
  ## getPublicKeyConfig20181105
  ## Return public key configuration informaation
  ##   Id: string (required)
  ##     : Request the ID for the public key configuration.
  var path_602548 = newJObject()
  add(path_602548, "Id", newJString(Id))
  result = call_602547.call(path_602548, nil, nil, nil, nil)

var getPublicKeyConfig20181105* = Call_GetPublicKeyConfig20181105_602535(
    name: "getPublicKeyConfig20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/public-key/{Id}/config",
    validator: validate_GetPublicKeyConfig20181105_602536, base: "/",
    url: url_GetPublicKeyConfig20181105_602537,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStreamingDistribution20181105_602580 = ref object of OpenApiRestCall_601389
proc url_UpdateStreamingDistribution20181105_602582(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-11-05/streaming-distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateStreamingDistribution20181105_602581(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update a streaming distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602583 = path.getOrDefault("Id")
  valid_602583 = validateParameter(valid_602583, JString, required = true,
                                 default = nil)
  if valid_602583 != nil:
    section.add "Id", valid_602583
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the streaming distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602584 = header.getOrDefault("X-Amz-Signature")
  valid_602584 = validateParameter(valid_602584, JString, required = false,
                                 default = nil)
  if valid_602584 != nil:
    section.add "X-Amz-Signature", valid_602584
  var valid_602585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602585 = validateParameter(valid_602585, JString, required = false,
                                 default = nil)
  if valid_602585 != nil:
    section.add "X-Amz-Content-Sha256", valid_602585
  var valid_602586 = header.getOrDefault("X-Amz-Date")
  valid_602586 = validateParameter(valid_602586, JString, required = false,
                                 default = nil)
  if valid_602586 != nil:
    section.add "X-Amz-Date", valid_602586
  var valid_602587 = header.getOrDefault("X-Amz-Credential")
  valid_602587 = validateParameter(valid_602587, JString, required = false,
                                 default = nil)
  if valid_602587 != nil:
    section.add "X-Amz-Credential", valid_602587
  var valid_602588 = header.getOrDefault("X-Amz-Security-Token")
  valid_602588 = validateParameter(valid_602588, JString, required = false,
                                 default = nil)
  if valid_602588 != nil:
    section.add "X-Amz-Security-Token", valid_602588
  var valid_602589 = header.getOrDefault("If-Match")
  valid_602589 = validateParameter(valid_602589, JString, required = false,
                                 default = nil)
  if valid_602589 != nil:
    section.add "If-Match", valid_602589
  var valid_602590 = header.getOrDefault("X-Amz-Algorithm")
  valid_602590 = validateParameter(valid_602590, JString, required = false,
                                 default = nil)
  if valid_602590 != nil:
    section.add "X-Amz-Algorithm", valid_602590
  var valid_602591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602591 = validateParameter(valid_602591, JString, required = false,
                                 default = nil)
  if valid_602591 != nil:
    section.add "X-Amz-SignedHeaders", valid_602591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602593: Call_UpdateStreamingDistribution20181105_602580;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update a streaming distribution. 
  ## 
  let valid = call_602593.validator(path, query, header, formData, body)
  let scheme = call_602593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602593.url(scheme.get, call_602593.host, call_602593.base,
                         call_602593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602593, url, valid)

proc call*(call_602594: Call_UpdateStreamingDistribution20181105_602580;
          body: JsonNode; Id: string): Recallable =
  ## updateStreamingDistribution20181105
  ## Update a streaming distribution. 
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The streaming distribution's id.
  var path_602595 = newJObject()
  var body_602596 = newJObject()
  if body != nil:
    body_602596 = body
  add(path_602595, "Id", newJString(Id))
  result = call_602594.call(path_602595, nil, nil, nil, body_602596)

var updateStreamingDistribution20181105* = Call_UpdateStreamingDistribution20181105_602580(
    name: "updateStreamingDistribution20181105", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/streaming-distribution/{Id}/config",
    validator: validate_UpdateStreamingDistribution20181105_602581, base: "/",
    url: url_UpdateStreamingDistribution20181105_602582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistributionConfig20181105_602566 = ref object of OpenApiRestCall_601389
proc url_GetStreamingDistributionConfig20181105_602568(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-11-05/streaming-distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStreamingDistributionConfig20181105_602567(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the configuration information about a streaming distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602569 = path.getOrDefault("Id")
  valid_602569 = validateParameter(valid_602569, JString, required = true,
                                 default = nil)
  if valid_602569 != nil:
    section.add "Id", valid_602569
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
  var valid_602570 = header.getOrDefault("X-Amz-Signature")
  valid_602570 = validateParameter(valid_602570, JString, required = false,
                                 default = nil)
  if valid_602570 != nil:
    section.add "X-Amz-Signature", valid_602570
  var valid_602571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602571 = validateParameter(valid_602571, JString, required = false,
                                 default = nil)
  if valid_602571 != nil:
    section.add "X-Amz-Content-Sha256", valid_602571
  var valid_602572 = header.getOrDefault("X-Amz-Date")
  valid_602572 = validateParameter(valid_602572, JString, required = false,
                                 default = nil)
  if valid_602572 != nil:
    section.add "X-Amz-Date", valid_602572
  var valid_602573 = header.getOrDefault("X-Amz-Credential")
  valid_602573 = validateParameter(valid_602573, JString, required = false,
                                 default = nil)
  if valid_602573 != nil:
    section.add "X-Amz-Credential", valid_602573
  var valid_602574 = header.getOrDefault("X-Amz-Security-Token")
  valid_602574 = validateParameter(valid_602574, JString, required = false,
                                 default = nil)
  if valid_602574 != nil:
    section.add "X-Amz-Security-Token", valid_602574
  var valid_602575 = header.getOrDefault("X-Amz-Algorithm")
  valid_602575 = validateParameter(valid_602575, JString, required = false,
                                 default = nil)
  if valid_602575 != nil:
    section.add "X-Amz-Algorithm", valid_602575
  var valid_602576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602576 = validateParameter(valid_602576, JString, required = false,
                                 default = nil)
  if valid_602576 != nil:
    section.add "X-Amz-SignedHeaders", valid_602576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602577: Call_GetStreamingDistributionConfig20181105_602566;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the configuration information about a streaming distribution. 
  ## 
  let valid = call_602577.validator(path, query, header, formData, body)
  let scheme = call_602577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602577.url(scheme.get, call_602577.host, call_602577.base,
                         call_602577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602577, url, valid)

proc call*(call_602578: Call_GetStreamingDistributionConfig20181105_602566;
          Id: string): Recallable =
  ## getStreamingDistributionConfig20181105
  ## Get the configuration information about a streaming distribution. 
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_602579 = newJObject()
  add(path_602579, "Id", newJString(Id))
  result = call_602578.call(path_602579, nil, nil, nil, nil)

var getStreamingDistributionConfig20181105* = Call_GetStreamingDistributionConfig20181105_602566(
    name: "getStreamingDistributionConfig20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/streaming-distribution/{Id}/config",
    validator: validate_GetStreamingDistributionConfig20181105_602567, base: "/",
    url: url_GetStreamingDistributionConfig20181105_602568,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributionsByWebACLId20181105_602597 = ref object of OpenApiRestCall_601389
proc url_ListDistributionsByWebACLId20181105_602599(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "WebACLId" in path, "`WebACLId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2018-11-05/distributionsByWebACLId/"),
               (kind: VariableSegment, value: "WebACLId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDistributionsByWebACLId20181105_602598(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   WebACLId: JString (required)
  ##           : The ID of the AWS WAF web ACL that you want to list the associated distributions. If you specify "null" for the ID, the request returns a list of the distributions that aren't associated with a web ACL. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `WebACLId` field"
  var valid_602600 = path.getOrDefault("WebACLId")
  valid_602600 = validateParameter(valid_602600, JString, required = true,
                                 default = nil)
  if valid_602600 != nil:
    section.add "WebACLId", valid_602600
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: JString
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  section = newJObject()
  var valid_602601 = query.getOrDefault("Marker")
  valid_602601 = validateParameter(valid_602601, JString, required = false,
                                 default = nil)
  if valid_602601 != nil:
    section.add "Marker", valid_602601
  var valid_602602 = query.getOrDefault("MaxItems")
  valid_602602 = validateParameter(valid_602602, JString, required = false,
                                 default = nil)
  if valid_602602 != nil:
    section.add "MaxItems", valid_602602
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
  var valid_602603 = header.getOrDefault("X-Amz-Signature")
  valid_602603 = validateParameter(valid_602603, JString, required = false,
                                 default = nil)
  if valid_602603 != nil:
    section.add "X-Amz-Signature", valid_602603
  var valid_602604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602604 = validateParameter(valid_602604, JString, required = false,
                                 default = nil)
  if valid_602604 != nil:
    section.add "X-Amz-Content-Sha256", valid_602604
  var valid_602605 = header.getOrDefault("X-Amz-Date")
  valid_602605 = validateParameter(valid_602605, JString, required = false,
                                 default = nil)
  if valid_602605 != nil:
    section.add "X-Amz-Date", valid_602605
  var valid_602606 = header.getOrDefault("X-Amz-Credential")
  valid_602606 = validateParameter(valid_602606, JString, required = false,
                                 default = nil)
  if valid_602606 != nil:
    section.add "X-Amz-Credential", valid_602606
  var valid_602607 = header.getOrDefault("X-Amz-Security-Token")
  valid_602607 = validateParameter(valid_602607, JString, required = false,
                                 default = nil)
  if valid_602607 != nil:
    section.add "X-Amz-Security-Token", valid_602607
  var valid_602608 = header.getOrDefault("X-Amz-Algorithm")
  valid_602608 = validateParameter(valid_602608, JString, required = false,
                                 default = nil)
  if valid_602608 != nil:
    section.add "X-Amz-Algorithm", valid_602608
  var valid_602609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602609 = validateParameter(valid_602609, JString, required = false,
                                 default = nil)
  if valid_602609 != nil:
    section.add "X-Amz-SignedHeaders", valid_602609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602610: Call_ListDistributionsByWebACLId20181105_602597;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ## 
  let valid = call_602610.validator(path, query, header, formData, body)
  let scheme = call_602610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602610.url(scheme.get, call_602610.host, call_602610.base,
                         call_602610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602610, url, valid)

proc call*(call_602611: Call_ListDistributionsByWebACLId20181105_602597;
          WebACLId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listDistributionsByWebACLId20181105
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ##   Marker: string
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: string
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  ##   WebACLId: string (required)
  ##           : The ID of the AWS WAF web ACL that you want to list the associated distributions. If you specify "null" for the ID, the request returns a list of the distributions that aren't associated with a web ACL. 
  var path_602612 = newJObject()
  var query_602613 = newJObject()
  add(query_602613, "Marker", newJString(Marker))
  add(query_602613, "MaxItems", newJString(MaxItems))
  add(path_602612, "WebACLId", newJString(WebACLId))
  result = call_602611.call(path_602612, query_602613, nil, nil, nil)

var listDistributionsByWebACLId20181105* = Call_ListDistributionsByWebACLId20181105_602597(
    name: "listDistributionsByWebACLId20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/distributionsByWebACLId/{WebACLId}",
    validator: validate_ListDistributionsByWebACLId20181105_602598, base: "/",
    url: url_ListDistributionsByWebACLId20181105_602599,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource20181105_602614 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource20181105_602616(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource20181105_602615(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List tags for a CloudFront resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
  ##           :  An ARN of a CloudFront resource.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Resource` field"
  var valid_602617 = query.getOrDefault("Resource")
  valid_602617 = validateParameter(valid_602617, JString, required = true,
                                 default = nil)
  if valid_602617 != nil:
    section.add "Resource", valid_602617
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
  var valid_602618 = header.getOrDefault("X-Amz-Signature")
  valid_602618 = validateParameter(valid_602618, JString, required = false,
                                 default = nil)
  if valid_602618 != nil:
    section.add "X-Amz-Signature", valid_602618
  var valid_602619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602619 = validateParameter(valid_602619, JString, required = false,
                                 default = nil)
  if valid_602619 != nil:
    section.add "X-Amz-Content-Sha256", valid_602619
  var valid_602620 = header.getOrDefault("X-Amz-Date")
  valid_602620 = validateParameter(valid_602620, JString, required = false,
                                 default = nil)
  if valid_602620 != nil:
    section.add "X-Amz-Date", valid_602620
  var valid_602621 = header.getOrDefault("X-Amz-Credential")
  valid_602621 = validateParameter(valid_602621, JString, required = false,
                                 default = nil)
  if valid_602621 != nil:
    section.add "X-Amz-Credential", valid_602621
  var valid_602622 = header.getOrDefault("X-Amz-Security-Token")
  valid_602622 = validateParameter(valid_602622, JString, required = false,
                                 default = nil)
  if valid_602622 != nil:
    section.add "X-Amz-Security-Token", valid_602622
  var valid_602623 = header.getOrDefault("X-Amz-Algorithm")
  valid_602623 = validateParameter(valid_602623, JString, required = false,
                                 default = nil)
  if valid_602623 != nil:
    section.add "X-Amz-Algorithm", valid_602623
  var valid_602624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602624 = validateParameter(valid_602624, JString, required = false,
                                 default = nil)
  if valid_602624 != nil:
    section.add "X-Amz-SignedHeaders", valid_602624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602625: Call_ListTagsForResource20181105_602614; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List tags for a CloudFront resource.
  ## 
  let valid = call_602625.validator(path, query, header, formData, body)
  let scheme = call_602625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602625.url(scheme.get, call_602625.host, call_602625.base,
                         call_602625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602625, url, valid)

proc call*(call_602626: Call_ListTagsForResource20181105_602614; Resource: string): Recallable =
  ## listTagsForResource20181105
  ## List tags for a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  var query_602627 = newJObject()
  add(query_602627, "Resource", newJString(Resource))
  result = call_602626.call(nil, query_602627, nil, nil, nil)

var listTagsForResource20181105* = Call_ListTagsForResource20181105_602614(
    name: "listTagsForResource20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/tagging#Resource",
    validator: validate_ListTagsForResource20181105_602615, base: "/",
    url: url_ListTagsForResource20181105_602616,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource20181105_602628 = ref object of OpenApiRestCall_601389
proc url_TagResource20181105_602630(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource20181105_602629(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Add tags to a CloudFront resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Resource` field"
  var valid_602631 = query.getOrDefault("Resource")
  valid_602631 = validateParameter(valid_602631, JString, required = true,
                                 default = nil)
  if valid_602631 != nil:
    section.add "Resource", valid_602631
  var valid_602645 = query.getOrDefault("Operation")
  valid_602645 = validateParameter(valid_602645, JString, required = true,
                                 default = newJString("Tag"))
  if valid_602645 != nil:
    section.add "Operation", valid_602645
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
  var valid_602646 = header.getOrDefault("X-Amz-Signature")
  valid_602646 = validateParameter(valid_602646, JString, required = false,
                                 default = nil)
  if valid_602646 != nil:
    section.add "X-Amz-Signature", valid_602646
  var valid_602647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602647 = validateParameter(valid_602647, JString, required = false,
                                 default = nil)
  if valid_602647 != nil:
    section.add "X-Amz-Content-Sha256", valid_602647
  var valid_602648 = header.getOrDefault("X-Amz-Date")
  valid_602648 = validateParameter(valid_602648, JString, required = false,
                                 default = nil)
  if valid_602648 != nil:
    section.add "X-Amz-Date", valid_602648
  var valid_602649 = header.getOrDefault("X-Amz-Credential")
  valid_602649 = validateParameter(valid_602649, JString, required = false,
                                 default = nil)
  if valid_602649 != nil:
    section.add "X-Amz-Credential", valid_602649
  var valid_602650 = header.getOrDefault("X-Amz-Security-Token")
  valid_602650 = validateParameter(valid_602650, JString, required = false,
                                 default = nil)
  if valid_602650 != nil:
    section.add "X-Amz-Security-Token", valid_602650
  var valid_602651 = header.getOrDefault("X-Amz-Algorithm")
  valid_602651 = validateParameter(valid_602651, JString, required = false,
                                 default = nil)
  if valid_602651 != nil:
    section.add "X-Amz-Algorithm", valid_602651
  var valid_602652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602652 = validateParameter(valid_602652, JString, required = false,
                                 default = nil)
  if valid_602652 != nil:
    section.add "X-Amz-SignedHeaders", valid_602652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602654: Call_TagResource20181105_602628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add tags to a CloudFront resource.
  ## 
  let valid = call_602654.validator(path, query, header, formData, body)
  let scheme = call_602654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602654.url(scheme.get, call_602654.host, call_602654.base,
                         call_602654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602654, url, valid)

proc call*(call_602655: Call_TagResource20181105_602628; Resource: string;
          body: JsonNode; Operation: string = "Tag"): Recallable =
  ## tagResource20181105
  ## Add tags to a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_602656 = newJObject()
  var body_602657 = newJObject()
  add(query_602656, "Resource", newJString(Resource))
  add(query_602656, "Operation", newJString(Operation))
  if body != nil:
    body_602657 = body
  result = call_602655.call(nil, query_602656, nil, nil, body_602657)

var tagResource20181105* = Call_TagResource20181105_602628(
    name: "tagResource20181105", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/tagging#Operation=Tag&Resource",
    validator: validate_TagResource20181105_602629, base: "/",
    url: url_TagResource20181105_602630, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource20181105_602658 = ref object of OpenApiRestCall_601389
proc url_UntagResource20181105_602660(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource20181105_602659(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove tags from a CloudFront resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Resource` field"
  var valid_602661 = query.getOrDefault("Resource")
  valid_602661 = validateParameter(valid_602661, JString, required = true,
                                 default = nil)
  if valid_602661 != nil:
    section.add "Resource", valid_602661
  var valid_602662 = query.getOrDefault("Operation")
  valid_602662 = validateParameter(valid_602662, JString, required = true,
                                 default = newJString("Untag"))
  if valid_602662 != nil:
    section.add "Operation", valid_602662
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
  var valid_602663 = header.getOrDefault("X-Amz-Signature")
  valid_602663 = validateParameter(valid_602663, JString, required = false,
                                 default = nil)
  if valid_602663 != nil:
    section.add "X-Amz-Signature", valid_602663
  var valid_602664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602664 = validateParameter(valid_602664, JString, required = false,
                                 default = nil)
  if valid_602664 != nil:
    section.add "X-Amz-Content-Sha256", valid_602664
  var valid_602665 = header.getOrDefault("X-Amz-Date")
  valid_602665 = validateParameter(valid_602665, JString, required = false,
                                 default = nil)
  if valid_602665 != nil:
    section.add "X-Amz-Date", valid_602665
  var valid_602666 = header.getOrDefault("X-Amz-Credential")
  valid_602666 = validateParameter(valid_602666, JString, required = false,
                                 default = nil)
  if valid_602666 != nil:
    section.add "X-Amz-Credential", valid_602666
  var valid_602667 = header.getOrDefault("X-Amz-Security-Token")
  valid_602667 = validateParameter(valid_602667, JString, required = false,
                                 default = nil)
  if valid_602667 != nil:
    section.add "X-Amz-Security-Token", valid_602667
  var valid_602668 = header.getOrDefault("X-Amz-Algorithm")
  valid_602668 = validateParameter(valid_602668, JString, required = false,
                                 default = nil)
  if valid_602668 != nil:
    section.add "X-Amz-Algorithm", valid_602668
  var valid_602669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602669 = validateParameter(valid_602669, JString, required = false,
                                 default = nil)
  if valid_602669 != nil:
    section.add "X-Amz-SignedHeaders", valid_602669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602671: Call_UntagResource20181105_602658; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from a CloudFront resource.
  ## 
  let valid = call_602671.validator(path, query, header, formData, body)
  let scheme = call_602671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602671.url(scheme.get, call_602671.host, call_602671.base,
                         call_602671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602671, url, valid)

proc call*(call_602672: Call_UntagResource20181105_602658; Resource: string;
          body: JsonNode; Operation: string = "Untag"): Recallable =
  ## untagResource20181105
  ## Remove tags from a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_602673 = newJObject()
  var body_602674 = newJObject()
  add(query_602673, "Resource", newJString(Resource))
  add(query_602673, "Operation", newJString(Operation))
  if body != nil:
    body_602674 = body
  result = call_602672.call(nil, query_602673, nil, nil, body_602674)

var untagResource20181105* = Call_UntagResource20181105_602658(
    name: "untagResource20181105", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/tagging#Operation=Untag&Resource",
    validator: validate_UntagResource20181105_602659, base: "/",
    url: url_UntagResource20181105_602660, schemes: {Scheme.Https, Scheme.Http})
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
